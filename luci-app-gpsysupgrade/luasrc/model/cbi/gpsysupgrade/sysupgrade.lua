module("luci.model.cbi.gpsysupgrade.sysupgrade", package.seeall)
local fs = require "nixio.fs"
local sys = require "luci.sys"
local util = require "luci.util"
local i18n = require "luci.i18n"
local ipkg = require("luci.model.ipkg")
local api = require "luci.model.cbi.gpsysupgrade.api"
local Variable1 = "http://192.168.123.199"
local Variable2 = "Op"

function get_system_version()
	local system_version = luci.sys.exec("[ -f '/etc/openwrt_version' ] && echo -n `cat /etc/openwrt_version` | tr -d '\n'")
    return system_version
end

function get_model()
	local model = luci.sys.exec("echo -n `cat /etc/model` | tr -d '\n'")
    return model
end

function check_update()
		needs_update, notice = false, false
		remote_version = luci.sys.exec("echo -n $(curl -fsSL " ..Variable1.. "/" ..Variable2.. "/version.txt) | tr -d '\n'")
		updatelogs = luci.sys.exec("echo -n $(curl -fsSL " ..Variable1.. "/" ..Variable2.. "/release.txt) | tr -d '\n'")
		remoteformat = remote_version
		fnotice = remote_version
		dateyr = remote_version
		if remoteformat > sysverformat then
			needs_update = true
			if currentTimeStamp > remoteformat or fnotice ~= "" then
				notice = fnotice
			end
		end
end

function to_check()
    if not model or model == "" then model = get_model() end
	system_version = get_system_version()
	sysverformat = system_version
	currentTimeStamp = os.date("%Y%m%d")
	if model == "string" then
		check_update()
		if fs.access("/sys/firmware/efi") then
			download_url = "" ..Variable1.. "/" ..Variable2.. "/" ..model.. "/" ..dateyr.. "-openwrt-x86-64-combined-squashfs-efi.img.gz"
		else
			download_url = "" ..Variable1.. "/" ..Variable2.. "/" ..model.. "/" ..dateyr.. "-openwrt-x86-64-combined-squashfs.img.gz"
		end
    elseif model == "Newifi-D2" then
		model = "newifi-d2"
		check_update()
        download_url = "" ..Variable1.. "/" ..Variable2.. "/" ..model.. "/" ..dateyr.. "-openwrt-ramips-mt7621-d-team_newifi-d2-squashfs-sysupgrade.bin"
    elseif model == "XY-C5" then
		model = "xy-c5"
		check_update()
        download_url = "" ..Variable1.. "/" ..Variable2.. "/" ..model.. "/" ..dateyr.. "-openwrt-ramips-mt7621-xiaoyu_xy-c5-squashfs-sysupgrade.bin"
	else
		local needs_update = false
		return {
            code = 1,
            error = i18n.translate("Can't determine MODEL, or MODEL not supported.")
			}
	end	

    if needs_update and not download_url then
        return {
            code = 1,
            now_version = system_version,
            version = remote_version,
            error = i18n.translate("New version found, but failed to get new version download url.")
        }
    end

    return {
        code = 0,
        update = needs_update,
		notice = notice,
        now_version = system_version,
        version = remote_version,
	logs = updatelogs,
        url = download_url
    }
end

function to_download(url)
    if not url or url == "" then
        return {code = 1, error = i18n.translate("Download url is required.")}
    end

    sys.call("/bin/rm -f /tmp/firmware_download.*")

    local tmp_file = util.trim(util.exec("mktemp -u -t firmware_download.XXXXXX"))

    local result = api.exec(api.curl, {api._unpack(api.curl_args), "-o", tmp_file, url}, nil, api.command_timeout) == 0

    if not result then
        api.exec("/bin/rm", {"-f", tmp_file})
        return {
            code = 1,
            error = i18n.translatef("File download failed or timed out: %s", url)
        }
    end

    return {code = 0, file = tmp_file}
end

function to_flash(file,retain)
    if not file or file == "" or not fs.access(file) then
        return {code = 1, error = i18n.translate("Firmware file is required.")}
    end
if not retain or retain == "" then
	local result = api.exec("/sbin/sysupgrade", {file}, nil, api.command_timeout) == 0
else
	local result = api.exec("/sbin/sysupgrade", {retain, file}, nil, api.command_timeout) == 0
end

    if not result or not fs.access(file) then
        return {
            code = 1,
            error = i18n.translatef("System upgrade failed")
        }
    end

    return {code = 0}
end
