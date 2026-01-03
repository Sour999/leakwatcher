# leakwatcher
分析 兜底流量
# luci-app-openclash-leakwatcher

## 功能
- 自动分析 OpenClash 兜底流量
- 区分国内 / 国际域名和 IP
- 生成 Rule-Provider YAML
- 支持定时执行与 GUI 配置

## 安装
opkg install luci-app-openclash-leakwatcher.ipk

## 使用说明
1. 开启插件
2. 设置日志路径
3. 配置 IP 库
4. 设置定时任务

## 生成文件说明
- CN-DOMAIN.yaml
- INTL-DOMAIN.yaml
- CN-IP.yaml
- INTL-IP.yaml
