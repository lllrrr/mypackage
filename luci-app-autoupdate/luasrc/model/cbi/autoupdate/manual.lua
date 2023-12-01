m = Map("autoupdate",translate("Manually Upgrade"),translate("Manually upgrade Firmware or Script"))
s = m:section(TypedSection,"autoupdate")
s.anonymous = true

check_updates = s:option (Button, "_check_updates", translate("Download Firmware"))
check_updates.inputtitle = translate ("Download Firmware")
check_updates.write = function()
	luci.sys.call ("rm -rf /tmp/tmp/*")
	luci.sys.call ("cat /dev/null > /tmp/autoupdate.log")
	luci.sys.call ("wget -P /tmp/tmp --timeout=50 http://$(uci -q get autoupdate.@autoupdate[0].github)/fw/$(uci -q get autoupdate.@autoupdate[0].flag).bin >> /tmp/autoupdate.log 2>&1")
	luci.sys.call ("wget -P /tmp/tmp --timeout=3 http://$(uci -q get autoupdate.@autoupdate[0].github)/fw/$(uci -q get autoupdate.@autoupdate[0].flag) >> /tmp/autoupdate.log 2>&1")
	luci.sys.call ("cd /tmp/tmp && md5sum -c $(uci -q get autoupdate.@autoupdate[0].flag) 2> /dev/null | grep OK >> /tmp/autoupdate.log")
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "autoupdate","log"))
end

upgrade_fw = s:option (Button, "_upgrade_fw", translate("Upgrade Firmware"))
upgrade_fw.inputtitle = translate ("Upgrade Firmware")
upgrade_fw.write = function()
	luci.sys.call ("sysupgrade -k -q /tmp/tmp/$(uci -q get autoupdate.@autoupdate[0].flag).bin >> /tmp/autoupdate.log 2>&1")
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "autoupdate","log"))
end

upgrade_fw = s:option (Button, "_upgrade_fw_reset", translate("Upgrade Firmware Reset Config"))
upgrade_fw.inputtitle = translate ("Upgrade Firmware Reset Config")
upgrade_fw.write = function()
	luci.sys.call ("sysupgrade -n -q /tmp/tmp/$(uci -q get autoupdate.@autoupdate[0].flag).bin >> /tmp/autoupdate.log 2>&1")
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "autoupdate","log"))
end

upgrade_config = s:option (Button, "_upgrade_config", translate("Upgrade Config"))
upgrade_config.inputtitle = translate ("Upgrade Config")
upgrade_config.write = function()
	luci.sys.call ("wget -P /tmp/tmp --timeout=3 http://$(uci -q get autoupdate.@autoupdate[0].github)/config/$(uci -q get autoupdate.@autoupdate[0].configf) >> /tmp/autoupdate.log 2>&1")
	luci.sys.call ("cp -f /tmp/tmp/$(uci -q get autoupdate.@autoupdate[0].configf) /etc/config/")
	luci.sys.call ("/etc/init.d/passwall restart > /dev/null 2>&1 &")
--	luci.sys.call ('echo "Update $(uci -q get autoupdate.@autoupdate[0].configf) success" >> /tmp/autoupdate.log')
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "autoupdate","log"))
end

upgrade_script = s:option (Button, "_upgrade_script", translate("Upgrade Script"))
upgrade_script.inputtitle = translate ("Upgrade Script")
upgrade_script.write = function()
	luci.sys.call ("wget -P /tmp/tmp --timeout=3 http://$(uci -q get autoupdate.@autoupdate[0].github)/script/$(uci -q get autoupdate.@autoupdate[0].scriptf) >> /tmp/autoupdate.log 2>&1")
--	luci.sys.call ("find $(uci -q get autoupdate.@autoupdate[0].scriptf) 2>> /tmp/autoupdate.log")
	luci.sys.call ("chmod +x /tmp/tmp/$(uci -q get autoupdate.@autoupdate[0].scriptf)")
	luci.sys.call ("sh /tmp/tmp/$(uci -q get autoupdate.@autoupdate[0].scriptf)")
	luci.sys.call ("/etc/init.d/passwall restart > /dev/null 2>&1 &")
--	luci.sys.call ('echo "Update $(uci -q get autoupdate.@autoupdate[0].scriptf) success" >> /tmp/autoupdate.log')
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "autoupdate","log"))
end

return m
