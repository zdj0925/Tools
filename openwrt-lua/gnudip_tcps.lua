md5    = require("md5")
socket = require("socket")
--获取wan口ip
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

function ddns_tcp_update_ip(uri, port, domain, user, passwd, wan, local_ip)
	local curr_ip = get_wan_ip(wan)
	if (curr_ip == '1.1.1.1') then
		print(string.format("%s.%s\t%s\t:IP[%s]\twan口不在线或配置错误", user, domain, wan, curr_ip))
		return curr_ip
	elseif (curr_ip == '1.1.1.2') then
		print(string.format("%s.%s\t%s\t:IP[%s]\t获取IP是出现错误", user, domain, wan, curr_ip))
		return curr_ip
	elseif (curr_ip == local_ip) then
		print(string.format("%s.%s\t%s\t:IP[%s]\t无变化无需更新", user, domain, wan, curr_ip))
		return curr_ip
	end
	local md5_pwd = md5.sumhexa(passwd) --将密码明文进行MD5哈希 
	local tcp = assert(socket.tcp()) --todo tcp 考虑再封装一下将查询也搞出来~~~
	tcp:settimeout(3)   --超时时间根据自己网络情况自行调节
	local conn = tcp:connect(uri, port)
	if (conn) then
		--print('connect '..uri..':'..port..'ok')
	else
		print('connect eror'..conn)
		return '0.0.0.0'
	end
	local salt= tcp:receive(10) --获取服务端加盐值
	if (salt) then 
		--print(salt)
	else
		print('获取加盐值失败')
		return '0.0.0.1'
	end
	md5_md5_pwd_salt = md5.sumhexa(md5_pwd.."."..salt) --(密码MD5哈希 + . + 盐 ) 再次进行MD5哈希
	local len = tcp:send(user..":"..md5_md5_pwd_salt..":"..domain..":0:"..curr_ip) --将 用户名:密码密文:域:0:本地ip 发送给服务端进行更新
	if (len) then 
		--print(len)
		print(string.format("%s.%s\t%s\t:IP[%s]\t更新成功", user, domain, wan, curr_ip))
	else
		print('更新IP地址失败')
		return '0.0.0.2'
	end

	tcp:close()
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
			if(nil == list[6]) then
				break
			end
			list[7] = ddns_tcp_update_ip(list[1],list[2], list[3], list[4], list[5], list[6],list[7])
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

local gnudip_tcps_conf = "/root/gnudip_tcp.conf"
local gnudip_tcps_confbak = "/root/gnudip_tcp.conf.bak"
print (os.date("%Y/%m/%d %H:%M:%S>>>>>>>>"))
main (gnudip_tcps_conf, gnudip_tcps_confbak)
print (os.date("%Y/%m/%d %H:%M:%S<<<<<<<<"))
