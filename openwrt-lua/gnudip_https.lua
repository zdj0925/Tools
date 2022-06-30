#!/usr/bin/lua
md5    = require("md5")
http = require("socket.http")
https = require("ssl.https")
ltn12  = require("ltn12")

function http.get(u)
	local t = {}
	local r, c, h = http.request{
		url = u,
		sink = ltn12.sink.table(t)
	}
	return r, c, h, table.concat(t)
end

function https.get(uri)
	local body, code, header, status = https.request(uri)
	--print (body, code, header, status )
	--local lcmd = "curl -G -s -w http_code:%{http_code} " ..uri
	--local lexe = io.popen(lcmd)
	--local msg = lexe:read("*all")
	--local code = string.match(msg,"http_code:(%d+)")
	return code, body 
end

function gen_passwd_hash(p,s)
	local lpw = p
	local lsalt = s
	--print (lsalt, lpw)
	return md5.sumhexa(md5.sumhexa(lpw).."."..lsalt)
end

function get_wan_ip(w)
	local wan_name = w
        local lcmd = "ip addr show dev "..wan_name
        local lexe = io.popen(lcmd)
        if (nil == lexe) then
                return '1.1.1.2'
        end
        local lip  = string.match(lexe:read("*all"), "%d+.%d+.%d+.%d+")
        if (nil == lip) then
                return '1.1.1.1'
        end
        return lip
end

function gen_upd_url(cgi,salt,time,sign,user,pass,domn,ip)
	local updurl = cgi
	local updurl = updurl.."?salt="..salt
	local updurl = updurl.."&time="..time
	local updurl = updurl.."&sign="..sign
	local updurl = updurl.."&user="..user
	local updurl = updurl.."&pass="..pass
	local updurl = updurl.."&domn="..domn
	local updurl = updurl.."&reqc=0"
	local updurl = updurl.."&addr="..ip
	return updurl
end

function get_salt_time_sign(b)
	local body = b
	--local i,j =  string.find(body, "salt")
    --local lsalt = string.sub(body, j+12, j+21)
	--local i,j  = string.find(body, "time")
	--local ltime = string.sub(body, j+12, j+21)
	--local i,j  = string.find(body, "sign")
	--local lsign = string.sub(body, j+12, j+43)
	local lsalt = string.match(body, "salt.-=\"([^\"]+)") 
	local ltime = string.match(body, "time.-=\"([^\"]+)") 
	local lsign = string.match(body, "sign.-=\"([^\"]+)") 
	return lsalt, ltime, lsign
end

function ddns_update_ip(host, domain, user, password, wan, ipaddr)
	local ddns_domn = domain
	local ddns_user = user 
	local ddns_pw   = password 
	local ddns_wan  = wan
	--local ddns_cgi  = "http://"..host.."/cgi-bin/gdipupdt.cgi"
	local ddns_cgi  = host
	local salt, time, sign

	local curr_ip = get_wan_ip(ddns_wan)
	if (curr_ip == '1.1.1.1') then
		print(string.format("%s.%s\t%s\t:IP[%s]\twan口不在线或配置错误", user, domain, wan, curr_ip))
		return curr_ip
	elseif (curr_ip == '1.1.1.2') then
		print(string.format("%s.%s\t%s\t:IP[%s]\t获取IP是出现错误", user, domain, wan, curr_ip))
		return curr_ip
	elseif (curr_ip == ipaddr) then
		print(string.format("%s.%s\t%s\t:IP[%s]\t无变化无需更新", user, domain, wan, curr_ip))
		return curr_ip
	end

	
	local  c, gbody = https.get(ddns_cgi)
	--print ("code"..c..",", "body:"..gbody)
	if (c == 200) then
		salt, time, sign = get_salt_time_sign(gbody)
	        --print ("关键信息:",salt, time, sign , curr_ip, pwh)
	else
		print(string.format("服务器[%s]错误[%s],无法更新[%s]的IP:%s",ddns_cgi, c, user, curr_ip))
		return "0.0.0.1"
	end
	local pwh = gen_passwd_hash(ddns_pw, salt)
	local upurl = gen_upd_url(ddns_cgi, salt, time, sign, ddns_user, pwh, ddns_domn, curr_ip)
	--print(gbody)
	--print (upurl)
	local c, gbody = https.get(upurl)
	if (c == 200) then
		print(string.format("域名[%s.%s]\t:IP[%s]\t更新成功", user, domain, curr_ip))
	else
		print(string.format("服务器[%s]错误[%s],无法更新[%s]的IP:%s",ddns_cgi, c, user, curr_ip))
		return "0.0.0.1"
	end
	--print (gbody)
	return curr_ip
end

function Split(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

function main (conf, confbak)
	local file = io.open(conf, "r") --读取conf文件
	local lines = {}
	local L = ""

	if ( nil == file ) then
		file = io.open(conf, "w") --创建conf文件
		file:close()
		file = io.open(confbak, "r") --读取备份配置文件
	elseif ( file ) then
	        local file_size = file:seek("end") --检查conf文件大小是否正常
		file:seek("set",0)
		if ( file_size < 10 ) then
			file:close()
			file = io.open(confbak, "r") --读取备份配置文件
		end
	end

	for line in file:lines() do
		repeat
			local list = Split(line, ",")
			if(nil == list[5]) then
				break
			end
			list[6] = ddns_update_ip(list[1],list[2], list[3], list[4], list[5], list[6])
			--print(list[7])
			for _,col in ipairs(list) do
				L = L..col..","
				--print(L)
			end
			lines[#lines + 1] = string.sub(L, 1, -2)
			L = ""
		until true

	end
	file:close()

	local cfg_file = io.open(conf, "r+") --将更新过的ip写入的conf中以便检查IP是更新
	if ( not cfg_file) then
		print(string.format("打开文件失败:%s\n",conf ))
		cfg_file:close()
		return nil
	end
	cfg_file:setvbuf("line")
	for _, L in ipairs (lines) do 
		cfg_file:write(L, "\n")
	end
	cfg_file:flush() --有机率写入文件大小为0 不知道是lua的问题还是openwrt的问题。添加flush也是不行。只能用bak文件保证程序一直运行~_~
	cfg_file:close()
end

local gnudip_tcps_conf = "/root/gnudip_https.conf"
local gnudip_tcps_confbak = "/root/gnudip_https.conf.bak"
print (os.date("%Y/%m/%d %H:%M:%S>>>>>>>>"))
main (gnudip_tcps_conf, gnudip_tcps_confbak)
print (os.date("%Y/%m/%d %H:%M:%S<<<<<<<<"))
