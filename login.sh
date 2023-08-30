#!/bin/sh

# Copyright 2020 BlackYau <blackyau426@gmail.com>
# GNU General Public License v3.0

dir="/tmp/log/sdutlogin/" && mkdir -p ${dir}
logfile="${dir}sdutlogin.log"
pidpath=${dir}run.pid
count=0
enable=$(uci get sdutlogin.@login[0].enable)
[ $enable -eq 0 ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] 未启用,停止运行..." > ${logfile} && exit 0
interval=$(($(uci get sdutlogin.@login[0].interval)*60)) # 把时间换算成秒
alternative="$(uci get sdutlogin.@login[0].alternative)"
USER_ACCOUNT=$(uci get sdutlogin.@login[0].username)
USER_PASSWORD=$(uci get sdutlogin.@login[0].password)
USER_ACCOUNT2=$(uci get sdutlogin.@login[0].username2)
USER_PASSWORD2=$(uci get sdutlogin.@login[0].password2)
auto_offline=$(uci get sdutlogin.@login[0].auto_offline)
WLAN_USER_IP="$(ubus call network.interface.wan status | grep '\"address\"\: \"' | grep -oE '([0-9]{1,3}.){3}.[0-9]{1,3}')"
response_file="/tmp/response.txt"



# 获取已连接设备数
function check(){
	local count=`cat /proc/net/arp|grep "0x2\|0x6"|awk '{print $1}'|grep -v "^169.254."|grep -v "^172.21."|grep -v "^$"|sort -u|wc -l $1`
	echo $count
}

# 控制log文件大小
function reducelog(){
	[ -f ${logfile} ] && local logrow=$(grep -c "" ${logfile}) || local logrow="0"
	[ $logrow -gt 500 ] && sed -i '1,100d' ${logfile} && echo "`date "+%Y-%m-%d %H:%M:%S"`  日志超出上限(500行)，删除前 100 条" >> ${logfile}
}

function login(){
	rm "$response_file"
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始拨号" >> ${logfile}
	echo "请求参数：" >> ${logfile}
    echo "用户名：$1" >> ${logfile}
    echo "密码：$2" >> ${logfile}
    echo "IP地址：$3" >> ${logfile}
	curl "http://111.17.200.130:801/eportal/portal/login?callback=dr1003&login_method=1&user_account=$1&user_password=$2&wlan_user_ip=$3&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=4.2.1&terminal_type=1&lang=zh-cn&v=6915&lang=zh" \
	  -H "Accept: */*" \
	  -H "Accept-Language: zh-CN,zh;q=0.9" \
	  -H "Connection: keep-alive" \
	  -H "Referer: http://111.17.200.130/" \
	  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36" \
	  -o "$response_file"
	response=$(cat "$response_file")
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] 服务器返回：$response" >> ${logfile}
}

# 如果在线返回真 关于返回值的问题:https://stackoverflow.com/a/43840545
function isonline(){
	local captiveReturnCode=`curl -s -I -m 10 -o /dev/null -s -w %{http_code} http://www.google.cn/generate_204`
	if [ "$captiveReturnCode" = "204" ]; then
		return
	fi
	false
}

function up(){
	if isonline; then
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] 您已连接到网络!" >> ${logfile}
		sleep 1 && return
	fi

	# Login
	curl -m 5  https://www.baidu.com/ > baidu.com

	check_status=`curl -I -m 5 -s -w "%{http_code}\n" -o /dev/null www.baidu.com`
	echo $check_status >> ${logfile}

	if [[ $check_status != 200  ]]
	then
   	 echo "[$(date '+%Y-%m-%d %H:%M:%S')] Not signed in yet" >> ${logfile}
	 login $USER_ACCOUNT $USER_PASSWORD $WLAN_USER_IP
	fi

	if isonline; then
		ntpd -n -q -p ntp1.aliyun.com  # 登录成功后校准时间
		wait # 等待校准时间完毕
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录成功!" >> ${logfile} && sleep 2 && return
	else
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录失败" >> ${logfile}
		if [ "$alternative" = "1" ]; then
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 尝试使用备选账号登录..." >> ${logfile}
                    login $USER_ACCOUNT2 $USER_PASSWORD2 $WLAN_USER_IP
                    sleep 3
                    if isonline; then
                    	echo "[$(date '+%Y-%m-%d %H:%M:%S')] 备选账号认证成功！" >> ${logfile}
                    else
                        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 备选账号认证失败！" >> ${logfile}
                    fi
                else
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 认证失败，重试..." >> ${logfile}
                fi  

	fi
}

function logout(){
	local resultCode=$(curl http://111.17.200.130:801/eportal/portal/logout?callback=dr1003&login_method=1&user_account=drcom&user_password=123&ac_logout=0&register_mode=1&wlan_user_ip=${WLAN_USER_IP}&wlan_user_ipv6=&wlan_vlan_id=0&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=4.2.1&v=7219&lang=zh)
	if [ "$resultCode" = "200" ]; then
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] 成功下线！" >> ${logfile}
		sleep 2 && up
	else
		echo $resultCode
		echo -n "[$(date '+%Y-%m-%d %H:%M:%S')] 下线失败" >> ${logfile}
		echo "$(curl http://111.17.200.130:801/eportal/portal/logout?callback=dr1003&login_method=1&user_account=drcom&user_password=123&ac_logout=0&register_mode=1&wlan_user_ip=${WLAN_USER_IP}&wlan_user_ipv6=&wlan_vlan_id=0&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=4.2.1&v=7219&lang=zh)" >> ${logfile}
	fi
}

if [ -f ${pidpath} ]; then
    echo "终止之前的进程: $(cat $pidpath)"
    kill -9 $(cat $pidpath)>/dev/null 2>&1
    rm -rf $pidpath
    sleep 1
fi
echo $$ > $pidpath

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 进程已启动 pid:$(cat $pidpath)" > ${logfile}

while [ $enable -eq 1 ]; do  # 已启用脚本
	tmp_count=$(check)
	if [ $tmp_count -gt 0 ]; then  # 已连接的设备>0才会进行下面的操作
		up
		wait
		if [ $auto_offline -eq 1 ]; then
			if [ $tmp_count -gt $count ]; then  # 如果当前已连接设备数，超过了上一次判断时的已连接设备数，就开始自动退出登录
				echo "[$(date '+%Y-%m-%d %H:%M:%S')] 当前已连接$tmp_count个设备, 上次检测时有$count个设备，开始退出登录" >> ${logfile} && logout
			fi
			count=$tmp_count  # 连接设备变少了也要记录
		fi
	fi
	reducelog
	sleep $interval
done
