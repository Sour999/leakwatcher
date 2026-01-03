-- 控制器文件: luci/controller/leakwatcher.lua
module("luci.controller.leakwatcher", package.seeall)

function index()
    -- 只允许 admin 访问
    if not nixio.fs.access("/etc/config/leakwatcher") then
        return
    end

    -- 系统菜单
    entry({"admin", "services", "leakwatcher"}, cbi("leakwatcher"), _("LeakWatcher"), 90).dependent = true
end
