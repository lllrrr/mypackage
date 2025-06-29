local nt = require "luci.sys".net
local fs = require "nixio.fs"
local e = luci.model.uci.cursor()
local net = require "luci.model.network".init()
local sys = require "luci.sys"
local ifaces = sys.net:devices()

m = Map("serverchan", translate("ServerChan"),
translate("「Server酱」，英文名「ServerChan」，是一款从服务器推送报警信息和日志到微信的工具。<br /><br />如果你在使用中遇到问题，请到这里提交：")
)

m:section(SimpleSection).template  = "serverchan/serverchan_status"

s = m:section(NamedSection, "serverchan", "serverchan", translate(""))
s:tab("basic", translate("基本设置"))
s:tab("content", translate("推送内容"))
s:tab("ipset", translate("自动封禁"))
s:tab("crontab", translate("定时推送"))
s:tab("disturb", translate("免打扰"))
s.addremove = false
s.anonymous = true

-- 基本设置
a = s:taboption("basic", Flag, "serverchan_enable", translate("启用"))
a.rmempty = true

a = s:taboption("basic", MultiValue, "lite_enable", translate("精简模式"))
a:value("device", translate("精简当前设备列表"))
a:value("nowtime", translate("精简当前时间"))
a:value("content", translate("只推送标题"))
a.widget = "checkbox"
a.default = nil
a.optional = true

a = s:taboption("basic", ListValue, "jsonpath", translate("推送模式"))
a.default = "/usr/share/serverchan/api/serverchan.json"
a.rmempty = true
a:value("/usr/share/serverchan/api/serverchan.json", translate("微信 Server酱"))
a:value("/usr/share/serverchan/api/qywx_mpnews.json", translate("企业微信 图文消息"))
a:value("/usr/share/serverchan/api/qywx_markdown.json", translate("企业微信 markdown版（不支持公众号）"))
a:value("/usr/share/serverchan/api/wxpusher.json", translate("微信 wxpusher"))
a:value("/usr/share/serverchan/api/pushplus.json", translate("微信 pushplus"))
a:value("/usr/share/serverchan/api/telegram.json", translate("Telegram"))
a:value("/usr/share/serverchan/api/diy.json", translate("自定义推送"))

a = s:taboption("basic", Value, "sckey", translate('微信推送/新旧共用'), translate("").."Server酱 sendkey <a href='https://sct.ftqq.com/' target='_blank'>点击这里</a><br>")
a.rmempty = true
a:depends("jsonpath", "/usr/share/serverchan/api/serverchan.json")

a = s:taboption("basic", Value, "corpid", translate('企业ID(corpid)'), translate("").."获取说明 <a href='https://work.weixin.qq.com/api/doc/10013' target='_blank'>点击这里</a>")
a.rmempty = true
a:depends("jsonpath", "/usr/share/serverchan/api/qywx_mpnews.json")
a:depends("jsonpath", "/usr/share/serverchan/api/qywx_markdown.json")

a = s:taboption("basic", Value, "userid", translate('帐号(userid)'))
a.rmempty = true
a.description = translate("群发到应用请填入 @all ")
a:depends("jsonpath", "/usr/share/serverchan/api/qywx_mpnews.json")
a:depends("jsonpath", "/usr/share/serverchan/api/qywx_markdown.json")

a = s:taboption("basic", Value, "agentid", translate('应用id(agentid)'))
a.rmempty = true
a:depends("jsonpath", "/usr/share/serverchan/api/qywx_mpnews.json")
a:depends("jsonpath", "/usr/share/serverchan/api/qywx_markdown.json")

a = s:taboption("basic", Value, "corpsecret", translate('应用密钥(Secret)'))
a.rmempty = true
a:depends("jsonpath", "/usr/share/serverchan/api/qywx_mpnews.json")
a:depends("jsonpath", "/usr/share/serverchan/api/qywx_markdown.json")

a = s:taboption("basic", Value, "mediapath", translate('图片缩略图文件路径'))
a.rmempty = true
a.default = "/usr/share/serverchan/api/logo.jpg"
a:depends("jsonpath", "/usr/share/serverchan/api/qywx_mpnews.json")
a.description = translate("只支持 2MB 以内 JPG,PNG 格式 <br> 900*383 或 2.35:1 为佳 ")

a = s:taboption("basic", Value, "wxpusher_apptoken", translate('appToken'), translate("").."获取 appToken <a href='https://wxpusher.zjiecode.com/docs/#/?id=%e5%bf%ab%e9%80%9f%e6%8e%a5%e5%85%a5' target='_blank'>点击这里</a><br>")
a.rmempty = true
a:depends("jsonpath", "/usr/share/serverchan/api/wxpusher.json")

a = s:taboption("basic", Value,"wxpusher_uids",translate('uids'))
a.rmempty = true
a:depends("jsonpath", "/usr/share/serverchan/api/wxpusher.json")

a = s:taboption("basic", Value, "wxpusher_topicIds", translate('topicIds(群发)'), translate("").."接口说明 <a href='https://wxpusher.zjiecode.com/docs/#/?id=%e5%8f%91%e9%80%81%e6%b6%88%e6%81%af-1'target='_blank'>点击这里</a><br>")
a.rmempty = true
a:depends("jsonpath", "/usr/share/serverchan/api/wxpusher.json")

a = s:taboption("basic", Value, "pushplus_token", translate('pushplus_token'), translate("").."获取pushplus_token <a href='http://www.pushplus.plus/' target='_blank'>点击这里</a><br>")
a.rmempty = true
a:depends("jsonpath", "/usr/share/serverchan/api/pushplus.json")

a = s:taboption("basic", Value, "tg_token", translate("TG_token"), translate("").."获取机器人<a href='https://t.me/BotFather' target='_blank'>点击这里</a><br>与创建的机器人发一条消息，开启对话<br>")
a.rmempty = true
a:depends("jsonpath", "/usr/share/serverchan/api/telegram.json")

a = s:taboption("basic", Value, "chat_id", translate('TG_chatid'), translate("").."获取 chat_id <a href='https://t.me/getuserIDbot' target='_blank'>点击这里</a>")
a.rmempty = true
a:depends("jsonpath", "/usr/share/serverchan/api/telegram.json")

a = s:taboption("basic", TextValue, "diy_json", translate("自定义推送"))
a.optional = false
a.rows = 28
a.wrap = "soft"
a.cfgvalue = function(self, section)
	return fs.readfile("/usr/share/serverchan/api/diy.json")
end
a.write = function(self, section, value)
	fs.writefile("/usr/share/serverchan/api/diy.json", value:gsub("\r\n", "\n"))
end
a:depends("jsonpath", "/usr/share/serverchan/api/diy.json")

a = s:taboption("basic", Button, "__add", translate("发送测试"))
a.inputtitle = translate("发送")
a.inputstyle = "apply"
function a.write(self, section)
	luci.sys.call("cbi.apply")
	luci.sys.call("/usr/share/serverchan/serverchan test &")
end

a = s:taboption("basic", Value, "device_name", translate('本设备名称'))
a.rmempty = true
a.description = translate("在推送信息标题中会标识本设备名称，用于区分推送信息的来源设备")

a = s:taboption("basic", Value, "sleeptime", translate('检测时间间隔（s）'))
a.rmempty = true
a.optional = false
a.default = "60"
a.datatype = "and(uinteger,min(10))"
a.description = translate("越短的时间响应越及时，但会占用更多的系统资源")

a = s:taboption("basic", ListValue, "oui_data", translate("MAC设备信息数据库"))
a.rmempty = true
a.default = ""
a:value("", translate("关闭"))
a:value("1", translate("简化版"))
a:value("2", translate("完整版"))
a:value("3", translate("网络查询"))
a.description = translate("需下载 4.36 MB 原始数据，处理后完整版约 1.2 MB，简化版约 250 kB <br/>若无梯子，请勿使用网络查询")

a = s:taboption("basic", Flag, "oui_dir", translate("下载到内存"))
a.rmempty = true
a:depends("oui_data", "1")
a:depends("oui_data", "2")
a.description = translate("懒得做自动更新了，下载到内存中，重启会重新下载 <br/>若无梯子，还是下到机身吧")

a = s:taboption("basic", Flag, "reset_regularly", translate("每天零点重置流量数据"))
a.rmempty = true

a = s:taboption("basic", Flag, "debuglevel", translate("开启日志"))
a.rmempty = true

a = s:taboption("basic", DynamicList, "device_aliases", translate("设备别名"))
a.rmempty = true
a.description = translate("<br/> 请输入设备 MAC 和设备别名，用“-”隔开，如：<br/> XX:XX:XX:XX:XX:XX-我的手机")

-- 设备状态
a = s:taboption("content", ListValue, "serverchan_ipv4", translate("IPv4 变动通知"))
a.rmempty = true
a.default = ""
a:value("", translate("关闭"))
a:value("1", translate("通过接口获取"))
a:value("2", translate("通过URL获取"))

a = s:taboption("content", ListValue, "ipv4_interface", translate("接口名称"))
a.rmempty = true
a:depends({serverchan_ipv4 = "1"})
for _, iface in ipairs(ifaces) do
	if not (iface == "lo" or iface:match("^ifb.*")) then
		local nets = net:get_interface(iface)
		nets = nets and nets:get_networks() or {}
		for k, v in pairs(nets) do
			nets[k] = nets[k].sid
		end
		nets = table.concat(nets, ",")
		a:value(iface, ((#nets > 0) and "%s (%s)" % {iface, nets} or iface))
	end
end
a.description = translate("<br/>一般选择 wan 接口，多拨环境请自行选择")

a = s:taboption("content", TextValue, "ipv4_list", translate("IPv4 API列表"))
a.optional = false
a.rows = 8
a.wrap = "soft"
a.cfgvalue = function(self, section)
	return fs.readfile("/usr/share/serverchan/api/ipv4.list")
end
a.write = function(self, section, value)
	fs.writefile("/usr/share/serverchan/api/ipv4.list", value:gsub("\r\n", "\n"))
end
a.description = translate("<br/>会因服务器稳定性、连接频繁等原因导致获取失败<br/>如接口可以正常获取 IP，不推荐使用<br/>从以上列表中随机地址访问")
a:depends({serverchan_ipv4 = "2"})

a = s:taboption("content", ListValue, "serverchan_ipv6", translate("IPv6 变动通知"))
a.rmempty = true
a.default = "disable"
a:value("0", translate("关闭"))
a:value("1", translate("通过接口获取"))
a:value("2", translate("通过URL获取"))

a = s:taboption("content", ListValue, "ipv6_interface", translate("接口名称"))
a.rmempty = true
a:depends({serverchan_ipv6 = "1"})
for _, iface in ipairs(ifaces) do
	if not (iface == "lo" or iface:match("^ifb.*")) then
		local nets = net:get_interface(iface)
		nets = nets and nets:get_networks() or {}
		for k, v in pairs(nets) do
			nets[k] = nets[k].sid
		end
		nets = table.concat(nets, ",")
		a:value(iface, ((#nets > 0) and "%s (%s)" % {iface, nets} or iface))
	end
end
a.description = translate("<br/>一般选择 wan 接口，多拨环境请自行选择")

a = s:taboption("content", TextValue, "ipv6_list", translate("IPv6 API列表"))
a.optional = false
a.rows = 8
a.wrap = "soft"
a.cfgvalue = function(self, section)
	return fs.readfile("/usr/share/serverchan/api/ipv6.list")
end
a.write = function(self, section, value)
	fs.writefile("/usr/share/serverchan/api/ipv6.list", value:gsub("\r\n", "\n"))
end
a.description = translate("<br/>会因服务器稳定性、连接频繁等原因导致获取失败<br/>如接口可以正常获取 IP，不推荐使用<br/>从以上列表中随机地址访问")
a:depends({serverchan_ipv6 = "2"})

a = s:taboption("content", Flag, "serverchan_up", translate("设备上线通知"))
a.default = 1
a.rmempty = true

a = s:taboption("content", Flag, "serverchan_down", translate("设备下线通知"))
a.default = 1
a.rmempty = true

a = s:taboption("content", Flag, "cpuload_enable", translate("CPU 负载报警"))
a.default = 1
a.rmempty = true

a = s:taboption("content", Value, "cpuload", "负载报警阈值")
a.default = 2
a.rmempty = true
a:depends({cpuload_enable = "1"})

a = s:taboption("content", Flag, "temperature_enable", translate("CPU 温度报警"))
a.default = 1
a.rmempty = true
a.description = translate("请确认设备可以获取温度，如需修改命令，请移步高级设置")

a = s:taboption("content", Value, "temperature", "温度报警阈值")
a.rmempty = true
a.default = "80"
a.datatype = "and(uinteger,min(1))"
a:depends({temperature_enable = "1"})
a.description = translate("<br/>设备报警只会在连续五分钟超过设定值时才会推送<br/>而且一个小时内不会再提醒第二次")

a = s:taboption("content", Flag, "client_usage", translate("设备异常流量"))
a.default = 0
a.rmempty = true

a = s:taboption("content", Value, "client_usage_max", "每分钟流量限制")
a.default = "10M"
a.rmempty = true
a:depends({client_usage = "1"})
a.description = translate("设备异常流量警报（byte），你可以追加 K 或者 M")

a = s:taboption("content", Flag, "client_usage_disturb", translate("异常流量免打扰"))
a.default = 1
a.rmempty = true
a:depends({client_usage = "1"})

a = s:taboption("content", DynamicList, "client_usage_whitelist", translate("异常流量关注列表"))
nt.mac_hints(function(mac, name) a:value(mac, "%s (%s)" %{ mac, name }) end)
a.rmempty = true
a:depends({client_usage_disturb = "1"})
a.description = translate("请输入设备 MAC")

a = s:taboption("content", Flag, "web_logged", translate("web 登录提醒"))
a.default = 0
a.rmempty = true

a = s:taboption("content", Flag, "ssh_logged", translate("ssh 登录提醒"))
a.default = 0
a.rmempty = true

a = s:taboption("content", Flag, "web_login_failed", translate("web 错误尝试提醒"))
a.default = 0
a.rmempty = true

a = s:taboption("content", Flag, "ssh_login_failed", translate("ssh 错误尝试提醒"))
a.default = 0
a.rmempty = true

a = s:taboption("content", Value, "login_max_num", "错误尝试次数")
a.default = "3"
a.datatype = "and(uinteger,min(1))"
a:depends("web_login_failed", "1")
a:depends("ssh_login_failed", "1")
a.description = translate("超过次数后推送提醒，并可选自动拉黑")

-- 自动封禁

a = s:taboption("ipset", Flag, "web_login_black", translate("自动拉黑非法登录设备"))
a.default = 0
a.rmempty = true
a:depends("web_login_failed", "1")
a:depends("ssh_login_failed", "1")

a = s:taboption("ipset", Value, "ip_black_timeout", "拉黑时间(秒)")
a.default = "86400"
a.datatype = "and(uinteger,min(0))"
a:depends("web_login_black", "1")
a.description = translate("0 为永久拉黑，慎用<br>如不幸误操作，请更改设备 IP 进入 LUCI 界面清空规则")

a = s:taboption("ipset", DynamicList, "ip_white_list", translate("白名单 IP 列表"))
a.datatype = "ipaddr"
a.rmempty = true
luci.ip.neighbors({family = 4}, function(entry)
	if entry.reachable then
		a:value(entry.dest:string())
	end
end)
a:depends("web_logged", "1")
a:depends("ssh_logged", "1")
a:depends("web_login_failed", "1")
a:depends("ssh_login_failed", "1")
a.description = translate("忽略推送，仅在日志中记录，并忽略拉黑操作，暂不支持掩码位表示")

a = s:taboption("ipset", Flag, "port_knocking", translate("端口敲门"))
a.default = 0
a.rmempty = true
a.description = translate("登录成功后开放端口")

a = s:taboption("ipset", Value, "ip_port_white", "端口")
a.default = ""
a.rmempty = true
a.description = translate("例：'22'、'21:25'、'21:25,135:139'")
a:depends("port_knocking", "1")

a = s:taboption("ipset", DynamicList, "port_forward_list", "端口转发")
a.default = ""
a.rmempty = true
a.description = translate("例：将本机(10.0.0.1)的 13389 端口转发到 10.0.0.2 的3389：<br/>'10.0.0.1,13389,10.0.0.2,3389'<br/>IPv6 未测试")
a:depends("port_knocking", "1")

a = s:taboption("ipset", Value, "ip_white_timeout", "放行时间(秒)")
a.default = "600"
a.rmempty = true
a.datatype = "and(uinteger,min(0))"
a.description = translate("0 为永久放行，慎用<br/>连接成功后不断开就不需要重新连接，故不需要设置太大<br/>注：响应时间与检测间隔和每一次检测所需的时间相关，故反应不是很快，将就用吧")
a:depends("port_knocking", "1")

a = s:taboption("ipset", TextValue, "ip_black_list", translate("IP 黑名单列表"))
a.optional = false
a.rows = 8
a.wrap = "soft"
a.cfgvalue = function(self, section)
    return fs.readfile("/usr/share/serverchan/api/ip_blacklist")
end
a.write = function(self, section, value)
    fs.writefile("/usr/share/serverchan/api/ip_blacklist", value:gsub("\r\n", "\n"))
end
a:depends("web_login_black", "1")
a.description = translate("可在此处添加或删除，timeout 后的数字为剩余时间(秒)，添加时只需要输入 IP")

-- 定时推送
a = s:taboption("crontab", ListValue, "crontab", translate("定时任务设定"))
a.rmempty = true
a.default = ""
a:value("", translate("关闭"))
a:value("1", translate("定时发送"))
a:value("2", translate("间隔发送"))

a = s:taboption("crontab", ListValue, "regular_time", translate("发送时间"))
a.rmempty = true
for t = 0, 23 do
a:value(t, translate("每天"..t.."点"))
end	
a.default = 8	
a.datatype = uinteger
a:depends("crontab", "1")

a = s:taboption("crontab", ListValue, "regular_time_2", translate("发送时间"))
a.rmempty = true
a:value("", translate("关闭"))
for t = 0, 23 do
a:value(t, translate("每天"..t.."点"))
end	
a.default = "关闭"
a.datatype = uinteger
a:depends("crontab", "1")

a = s:taboption("crontab", ListValue, "regular_time_3", translate("发送时间"))
a.rmempty = true

a:value("", translate("关闭"))
for t = 0, 23 do
a:value(t, translate("每天"..t.."点"))
end	
a.default = "关闭"
a.datatype = uinteger
a:depends("crontab", "1")

a = s:taboption("crontab", ListValue, "interval_time", translate("发送间隔"))
a.rmempty = true
for t = 1, 23 do
a:value(t, translate(t.."小时"))
end
a.default = 6
a.datatype = uinteger
a:depends("crontab", "2")
a.description = translate("<br/>从 00:00 开始，每 * 小时发送一次")

a = s:taboption("crontab", Value, "send_title", translate("微信推送标题"))
a:depends("crontab", "1")
a:depends("crontab", "2")
a.placeholder = "OpenWrt By tty228 路由状态："
a.description = translate("<br/>使用特殊符号可能会造成发送失败")

a = s:taboption("crontab", Flag, "router_status", translate("系统运行情况"))
a.default = 1
a:depends("crontab", "1")
a:depends("crontab", "2")

a = s:taboption("crontab", Flag, "router_temp", translate("设备温度"))
a.default = 1
a:depends("crontab", "1")
a:depends("crontab", "2")
 
a = s:taboption("crontab", Flag, "router_wan", translate("WAN信息"))
a.default = 1
a:depends("crontab", "1")
a:depends("crontab", "2")

a = s:taboption("crontab", Flag, "client_list", translate("客户端列表"))
a.default = 1
a:depends("crontab", "1")
a:depends("crontab", "2") 

e = s:taboption("crontab", Button, "_add", translate("手动发送"))
e.inputtitle = translate("发送")
e:depends("crontab", "1")
e:depends("crontab", "2")
e.inputstyle = "apply"
function e.write(self, section)
luci.sys.call("cbi.apply")
		luci.sys.call("/usr/share/serverchan/serverchan send &")
end

-- 免打扰
a = s:taboption("disturb", ListValue, "serverchan_sheep", translate("免打扰时段设置"), translate("在指定整点时间段内，暂停推送消息<br/>免打扰时间中，定时推送也会被阻止。"))
a.rmempty = true
a:value("", translate("关闭"))
a:value("1", translate("模式一：脚本挂起"))
a:value("2", translate("模式二：静默模式"))
a.description = translate("模式一停止一切检测，包括无人值守。")

a = s:taboption("disturb", ListValue, "starttime", translate("免打扰开始时间"))
a.rmempty = true

for t = 0, 23 do
a:value(t, translate("每天"..t.."点"))
end
a.default = 0
a.datatype = uinteger
a:depends({serverchan_sheep = "1"})
a:depends({serverchan_sheep = "2"})

a = s:taboption("disturb", ListValue, "endtime", translate("免打扰结束时间"))
a.rmempty = true

for t = 0, 23 do
a:value(t, translate("每天"..t.."点"))
end
a.default = 8
a.datatype = uinteger
a:depends({serverchan_sheep = "1"})
a:depends({serverchan_sheep = "2"})

a = s:taboption("disturb", ListValue, "macmechanism", translate("MAC过滤"))
a:value("", translate("disable"))
a:value("allow", translate("忽略列表内设备"))
a:value("block", translate("仅通知列表内设备"))
a:value("interface", translate("仅通知此接口设备"))
a.rmempty = true

a = s:taboption("disturb", DynamicList, "serverchan_whitelist", translate("忽略列表"))
nt.mac_hints(function(mac, name) a :value(mac, "%s (%s)" %{ mac, name }) end)
a.rmempty = true
a:depends({macmechanism = "allow"})
a.description = translate("AA:AA:AA:AA:AA:AA\\|BB:BB:BB:BB:BB:B 可以将多个 MAC 视为同一用户<br/>任一设备在线后不再推送，设备全部离线时才会推送，避免双 wifi 频繁推送")

a = s:taboption("disturb", DynamicList, "serverchan_blacklist", translate("关注列表"))
nt.mac_hints(function(mac, name) a:value(mac, "%s (%s)" %{ mac, name }) end)
a.rmempty = true
a:depends({macmechanism = "block"})
a.description = translate("AA:AA:AA:AA:AA:AA\\|BB:BB:BB:BB:BB:B 可以将多个 MAC 视为同一用户<br/>任一设备在线后不再推送，设备全部离线时才会推送，避免双 wifi 频繁推送")

a = s:taboption("disturb", ListValue, "serverchan_interface", translate("接口名称"))
a:depends({macmechanism = "interface"})
a.rmempty = true

for _, iface in ipairs(ifaces) do
	if not (iface == "lo" or iface:match("^ifb.*")) then
		local nets = net:get_interface(iface)
		nets = nets and nets:get_networks() or {}
		for k, v in pairs(nets) do
			nets[k] = nets[k].sid
		end
		nets = table.concat(nets, ",")
		a:value(iface, ((#nets > 0) and "%s (%s)" % {iface, nets} or iface))
	end
end

a = s:taboption("disturb", ListValue, "macmechanism2", translate("MAC过滤2"))
a:value("", translate("disable"))
a:value("MAC_online", translate("列表内任意设备在线时免打扰"))
a:value("MAC_offline", translate("列表内设备都离线后免打扰"))
a.rmempty = true

a = s:taboption("disturb", DynamicList, "MAC_online_list", translate("在线免打扰列表"))
nt.mac_hints(function(mac, name) a:value(mac, "%s (%s)" %{ mac, name }) end)
a.rmempty = true
a:depends({macmechanism2 = "MAC_online"})

a = s:taboption("disturb", DynamicList, "MAC_offline_list", translate("任意离线免打扰列表"))
nt.mac_hints(function(mac, name) a:value(mac, "%s (%s)" %{ mac, name }) end)
a.rmempty = true
a:depends({macmechanism2 = "MAC_offline"})

return m
