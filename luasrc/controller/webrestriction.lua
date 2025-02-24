module("luci.controller.webrestriction", package.seeall)

function index()
    -- 检查配置文件存在且可读
    if not nixio.fs.access("/etc/config/webrestriction", "r") then
        return
    end

    -- 主菜单路由配置
    entry({"admin", "control"}, alias("admin", "control", "webrestriction"), _("Control"), 44).index = true
    
    -- 子菜单：访问限制
    entry({"admin", "control", "webrestriction"}, cbi("webrestriction", {hideresetbtn=true}), _("访问限制"), 11).dependent = true
    
    -- 状态检测接口
    entry({"admin", "control", "webrestriction", "status"}, call("action_status")).leaf = true
end

function action_status()
    local response = {
        status = false,
        error = nil
    }

    -- 安全执行系统命令
    local function check_nft_rule()
        return luci.sys.execute(
            "nft list chain ip filter FORWARD | grep -q 'WEB_RESTRICTION'"
        ) == 0
    end

    -- 异常捕获
    local ok, err = pcall(function()
        response.status = check_nft_rule()
    end)

    if not ok then
        response.error = tostring(err)
    end

    -- 输出标准化 JSON
    luci.http.prepare_content("application/json")
    luci.http.write_json(response, true)  -- 启用格式化输出
end
