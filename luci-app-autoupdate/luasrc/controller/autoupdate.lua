module("luci.controller.autoupdate",package.seeall)

function index()
	entry({"admin", "services","autoupdate"}).dependent = true
	entry({"admin", "services","autoupdate", "show"}, call("show_menu")).leaf = true
	entry({"admin", "services","autoupdate", "hide"}, call("hide_menu")).leaf = true
	if nixio.fs.access("/etc/config/passwall_show") then
	entry({"admin", "services", "autoupdate"}, alias("admin", "services", "autoupdate", "main"),_("AutoUpdate"), 2).dependent = true
	end
	entry({"admin", "services", "autoupdate", "main"}, cbi("autoupdate/main"),_("Upgrade Config"), 10).leaf = true
	entry({"admin", "services", "autoupdate", "manual"}, cbi("autoupdate/manual"),_("Manually Upgrade"), 20).leaf = true
	entry({"admin", "services", "autoupdate", "log"}, form("autoupdate/log"),_("Upgrade Log"), 30).leaf = true

	entry({"admin", "services", "autoupdate", "print_log"}, call("print_log")).leaf = true
end

function print_log()
	luci.http.write(luci.sys.exec("tail -n 100 /tmp/autoupdate.log 2> /dev/null"))
end

function show_menu()
	luci.sys.call("touch /etc/config/passwall_show")
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "autoupdate"))
end

function hide_menu()
	luci.sys.call("rm -rf /etc/config/passwall_show")
	luci.http.redirect(luci.dispatcher.build_url("admin", "status", "overview"))
end