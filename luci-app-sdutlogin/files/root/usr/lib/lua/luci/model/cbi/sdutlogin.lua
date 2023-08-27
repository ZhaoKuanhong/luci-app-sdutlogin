-- Copyright 2020 BlackYau <blackyau426@gmail.com>
-- GNU General Public License v3.0


require("luci.sys")

m = Map("sdutlogin", translate("山理工校园网认证"), translate("自动连接网络,支持断线自动重连 mod from suselogin by Faspand"))

s = m:section(TypedSection, "login", "")
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "enable", translate("启用"), translate("启用后即会检测上网状态，并尝试自动拨号"))
enable.rmempty = false

name = s:option(Value, "username", translate("用户名(手机号)"))
name.rmempty = false
pass = s:option(Value, "password", translate("密码(身份证后6位或123123)"))
pass.password = true
pass.rmempty = false


interval = s:option(Value, "interval", translate("间隔时间"), translate("每隔多少时间(≥1)检测一下网络是否连接正常，如果网络异常则会尝试连接(单位:分钟)"))
interval.default = 5
interval.datatype = "min(1)"

auto_offline = s:option(Flag, "auto_offline", translate("自动下线(暂不可用，请勿开启)"), translate("启用后，如果有新设备连接路由器则会将网络下线重新登录一次，可减少因为多终端设备在线而导致的账号封禁（会导致网络波动游戏玩家慎用）"))
auto_offline.rmempty = false

success = s:option(DummyValue,"opennewwindow",translate("认证页面"))
success.description = translate("<input type=\"button\" class=\"cbi-button cbi-button-save\" value=\"打开认证页\" onclick=\"window.open('http://111.17.200.130/')\" /><input type=\"button\" class=\"cbi-button cbi-button-save\" value=\"打开自助服务\" onclick=\"window.open('http://111.17.200.130:8081/Self/login')\" /><br />可查看认证状态和管理在线设备")


local apply = luci.http.formvalue("cbi.apply")
if apply then
	io.popen("/etc/init.d/sdutlogin restart")
end

return m
