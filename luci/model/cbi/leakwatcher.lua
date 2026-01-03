-- 配置模型文件: luci/model/cbi/leakwatcher.lua
local m = Map("leakwatcher", "LeakWatcher", "管理兜底域名/IP抓取和YAML生成")

-- ------------------ 基本设置 ------------------
s = m:section(TypedSection, "settings", "基本设置")
s.addremove = false
s.anonymous = true

-- log 文件路径
log_file = s:option(Value, "log_file", "OpenClash Log 文件")
log_file.placeholder = "/tmp/openclash.log"
log_file.datatype = "string"

-- DNS 解析
dns_server = s:option(Value, "dns_server", "DNS 解析服务器")
dns_server.placeholder = "114.114.114.114"
dns_server.datatype = "ipaddr"

-- IP 库路径
ip_file = s:option(Value, "ip_file", "国内 IP 库文件")
ip_file.placeholder = "/etc/openclash/china_ip_list.txt"
ip_file.datatype = "file"

-- YAML 输出路径
yaml_path = s:option(Value, "yaml_path", "生成 YAML 文件路径")
yaml_path.placeholder = "/etc/openclash/rule_provider"
yaml_path.datatype = "directory"

-- ------------------ 定时任务 ------------------
cron = s:option(Flag, "enable_cron", "启用定时抓取")
cron.rmempty = false

cron_time = s:option(Value, "cron_time", "定时任务时间（Cron 格式）")
cron_time.placeholder = "0 23 * * *"
cron_time.datatype = "string"

-- ------------------ 后台执行 ------------------
run = s:option(Button, "run", "立即执行")
run.inputtitle = "开始抓取"
run.inputstyle = "apply"

function run.write()
    luci.sys.call("/etc/leakwatcher/leakwatcher.sh >> /tmp/leakwatcher.log 2>&1 &")
end

-- ------------------ 日志查看 ------------------
log = s:option(TextValue, "log_view", "执行日志")
log.rows = 15
log.readonly = true
log.wrap = "off"

function log.cfgvalue()
    return luci.sys.exec("cat /tmp/leakwatcher.log 2>/dev/null")
end

return m
