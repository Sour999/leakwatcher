#!/bin/sh
# ================= LeakWatcher v1.0 =================
# 功能: 分析 OpenClash 兜底域名/IP，生成国内/国际 YAML 文件
# ====================================================

# ---------------- 配置（可在 LuCI 界面修改） ----------------
CONFIG_FILE="/etc/config/leakwatcher"

# 从配置读取
LOG_FILE=$(uci get leakwatcher.settings.log_file 2>/dev/null || echo "/tmp/openclash.log")
DNS_SERVER=$(uci get leakwatcher.settings.dns_server 2>/dev/null || echo "114.114.114.114")
CHINA_IP_FILE=$(uci get leakwatcher.settings.ip_file 2>/dev/null || echo "/etc/openclash/china_ip_list.txt")
YAML_PATH=$(uci get leakwatcher.settings.yaml_path 2>/dev/null || echo "/etc/openclash/rule_provider")

# 临时 IP 集合名称
SET_NAME="cn_check_temp"

# ---------------- 初始化 ----------------
echo "[*] 初始化 China IP ipset..."
ipset destroy $SET_NAME 2>/dev/null
ipset create $SET_NAME hash:net 2>/dev/null

if [ -s "$CHINA_IP_FILE" ]; then
    sed 's/\r//g' "$CHINA_IP_FILE" | grep -E '^[0-9]' | while read -r ip; do
        ipset add $SET_NAME "$ip" 2>/dev/null
    done
fi

# 文件保存
CN_DOMAIN_LIST="/etc/leakwatcher/cn_leak_domain.list"
INTL_DOMAIN_LIST="/etc/leakwatcher/intl_leak_domain.list"
CN_IP_LIST="/etc/leakwatcher/cn_leak_ip.list"
INTL_IP_LIST="/etc/leakwatcher/intl_leak_ip.list"

mkdir -p /etc/leakwatcher
touch $CN_DOMAIN_LIST $INTL_DOMAIN_LIST $CN_IP_LIST $INTL_IP_LIST

# ---------------- 提取兜底域名 ----------------
echo "[*] 提取兜底域名..."
DOMAINS=$(grep "兜底" "$LOG_FILE" 2>/dev/null | grep -oE '([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}' | sort -u)

# ---------------- 分析域名/IP ----------------
echo "[*] 分析域名及对应 IP..."
for domain in $DOMAINS; do
    domain=$(echo "$domain" | tr -d '\r\n')
    # 查询 IP
    IPS=$(nslookup "$domain" "$DNS_SERVER" 2>/dev/null | grep -E 'Address|地址' | grep -v "$DNS_SERVER" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -vE '^(127\.|198\.18\.)' | sort -u)

    CN_COUNT=0
    TOTAL=0

    for ip in $IPS; do
        TOTAL=$((TOTAL + 1))
        if ipset test $SET_NAME "$ip" 2>/dev/null; then
            CN_COUNT=$((CN_COUNT + 1))
        fi
    done

    [ "$TOTAL" -eq 0 ] && continue
    RATIO=$(( (CN_COUNT*100)/TOTAL ))

    # 分类域名
    if [ "$RATIO" -ge 66 ]; then
        grep -qxF "$domain" "$CN_DOMAIN_LIST" 2>/dev/null || echo "$domain" >> "$CN_DOMAIN_LIST"
        echo "[CN ] $domain ($RATIO%)"
    else
        grep -qxF "$domain" "$INTL_DOMAIN_LIST" 2>/dev/null || echo "$domain" >> "$INTL_DOMAIN_LIST"
        echo "[INTL] $domain ($RATIO%)"
    fi

    # 分类 IP
    for ip in $IPS; do
        if ipset test $SET_NAME "$ip" 2>/dev/null; then
            grep -qxF "$ip" "$CN_IP_LIST" 2>/dev/null || echo "$ip" >> "$CN_IP_LIST"
        else
            grep -qxF "$ip" "$INTL_IP_LIST" 2>/dev/null || echo "$ip" >> "$INTL_IP_LIST"
        fi
    done
done

# ---------------- 生成 YAML ----------------
gen_yaml_domain() {
    list="$1"
    yaml="$2"
    {
        echo "payload:"
        sort -u "$list" | sed 's/^/  - DOMAIN,/'
    } > "$yaml"
}

gen_yaml_ip() {
    list="$1"
    yaml="$2"
    {
        echo "payload:"
        sort -u "$list" | sed 's/^/  - IP-CIDR,/; s/$/\/32,no-resolve/'
    } > "$yaml"
}

# 域名 YAML
gen_yaml_domain "$CN_DOMAIN_LIST" "$YAML_PATH/China-Domain-Auto.yaml"
gen_yaml_domain "$INTL_DOMAIN_LIST" "$YAML_PATH/Intl-Domain-Auto.yaml"

# IP YAML
gen_yaml_ip "$CN_IP_LIST" "$YAML_PATH/China-IP-Auto.yaml"
gen_yaml_ip "$INTL_IP_LIST" "$YAML_PATH/Intl-IP-Auto.yaml"

# ---------------- 清理 ----------------
ipset destroy $SET_NAME 2>/dev/null

echo "[✓] YAML 文件生成完成："
echo "    - $YAML_PATH/China-Domain-Auto.yaml"
echo "    - $YAML_PATH/Intl-Domain-Auto.yaml"
echo "    - $YAML_PATH/China-IP-Auto.yaml"
echo "    - $YAML_PATH/Intl-IP-Auto.yaml"
