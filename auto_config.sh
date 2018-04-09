#!/usr/bin/bash
	
usage="Usage:\n$0 -u username -p password -b build-version -i web_ip, -t web_port, -z zywaf_port, -d domain"\
"\n\t\tusername: zyprotect ftp username"\
"\n\t\tpassword: zyprotect ftp password"\
"\n\t\tusername: zyprotect build version eg: 1802, 4017"\
"\n\t\tweb_ip: the Web Site IP address"\
"\n\t\tweb_port: the Web Site listening port"\
"\n\t\tdomain: the Web Site domain name"

config_file="/usr/local/waf/etc/WAProperties.xml"

if [ "x$1" == "x" ]; then
	echo -e ${usage}
	exit 0
fi 

while getopts "u:p:b:i:t:z:d:m:" arg 
do
	case $arg in
		u)
			username=$OPTARG
		;;
		p)
			password=$OPTARG
		;;
		b)
			build_version=$OPTARG
		;;
		i)
			web_ip=$OPTARG
		;;
		t)
			web_port=$OPTARG
		;;
		z)
			zywaf_port=$OPTARG
		;;
		m)
			method=$OPTARG
		;;
		d)
			domain=$OPTARG
		;;
		?) 
			echo -e "${usage}"
			exit 1
		;;
	esac
done

if [ ! -e ${config_file} ]; then
	echo "Please install zyWAF first"
	exit 0
fi

if ! echo ${web_ip} | egrep "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" > /dev/null ; then
	echo "IP format is not right"
	exit 0
fi 

if ! echo ${web_port} | egrep [0-9]+ > /dev/null; then
	echo "Web Port format is not right"
	exit 0
fi
if ! echo ${zywaf_port} | egrep [0-9]+ > /dev/null; then
	echo "zyWAF Port format is not right"
fi


#  it is better to run xslt .
sed -i "s/<web-server-port>.*<\/web-server-port>/<web-server-port>${web_port}<\/web-server-port>/g" ${config_file}
sed -i "1,10s/<listen-port>.*<\/listen-port>/<listen-port>${zywaf_port}<\/listen-port>/g" ${config_file}
sed -i "1,10s/<web-server-name>.*<\/web-server-name>/<web-server-name>${web_ip}<\/web-server-name>/g" ${config_file}
if ! fgrep "<host-name>${domain}" ${config_file} > /dev/null; then
	sed -i "1,30s/<\/host-names>/<host-name>${domain}<\/host-name>\n<\/host-names>/g" ${config_file}
fi

head -n 40 $config_file | egrep "web-server-port|listen-port|web-server-name|host-name" 

echo "Please confirm the config change above, we will run chkconfig"
read -r -p "Are You Sure? [Y/n] " input
case $input in
	[nN]) exit 0;;
esac


chkconfig --add zywaf
chkconfig --list 

echo "Please confirm the auto start change from command chkconfig above. we will run firewall-cmd"
read -r -p "Are You Sure? [Y/n] " input
case $input in
	[nN]) exit 0;;
esac

firewall-cmd --permanent --zone=public --add-port=8020/tcp
firewall-cmd --permanent --zone=public --add-port=${zywaf_port}/tcp
firewall-cmd --reload
firewall-cmd --state
firewall-cmd --list-all

echo "Please confirm the fireall settings from command firewall-cmd above, we will run crawler"
read -r -p "Are You Sure? [Y/n] " input
case $input in
	[nN]) exit 0;;
esac

echo "We will run crawler"
if ! fgrep ${domain} /etc/hosts > /dev/null; then 
	echo  "127.0.0.1 ${domain}" >> /etc/hosts
fi
wget -r ${domain}

if fgrep ${domain} /etc/hosts > /dev/null; then 
	sed -i  "s/.*${domain}//g"  /etc/hosts
fi

cat /etc/hosts
echo "Please confirm /etc/hosts file"

