#!/usr/bin/bash
	
usage="Usage:\n$0 -u username -p password -b build-version -i web_ip, -t web_port, -z zywaf_port, -d domain  -m [full|auto]"\
"\n\t\tusername: zyprotect ftp username"\
"\n\t\tpassword: zyprotect ftp password"\
"\n\t\tusername: zyprotect build version eg: 1802, 4017"\
"\n\t\tweb_ip: the Web Site IP address"\
"\n\t\tweb_port: the Web Site listening port"\
"\n\t\tdomain: the Web Site domain name"\
"\n\t\tfull/auto: full: it will remove all WAF file and install whole files."\
"\n\t\t           auto: it only reinstall when their is a old zyWAF installation."



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

ftpgetimage()
{
	wget --ftp-user=${username} --ftp-password=${password}   ftp://lab.zyprotect.com:1483/images/${build_version}/zyWAF*${build_version}*.rpm
	return $?
}
if [ ! -e zyWAF*${build_version}*.rpm ]; then
	echo "rpm file do not exist , we will download it"
	ftpgetimage
fi

if [ $? != 0 ]; then
	echo "Fail to get rpm file"
	exit 1
fi
rpm_file=`ls -1 zyWAF*${build_version}*.rpm`
echo "Success get rpm file ${rpm_file}"

#######

file_name="zywaf_upgrade.log"
#these string will be parsed
NOT_ROOT="Need Root privileges"
VALID_PACKAGE="Valid zyWAF upgrade package"
INVALID_PACKAGE="Invalid zyWAF upgrade package"
SAME_OLDER_VERSION="Older or same then installed version"
UPGRADE_SUC="Upgrade system success"

validation()
{	
	/usr/bin/echo "start validation" >> /tmp/${file_name}
	/usr/bin/echo "validating if file chanaged file " >> /tmp/${file_name}
	/usr/bin/rpm -K ${rpm_package} 2> /dev/null
	if [ $? != 0 ]; then
	    /usr/bin/echo ${INVALID_PACKAGE}
	    return 1
	fi

	/usr/bin/rpm -qip ${rpm_package}  2> /dev/null | /usr/bin/fgrep  "Essential Web Protection Beyond Firewalls" >/dev/null
	if [ $? != 0 ];
	then
		/usr/bin/echo ${INVALID_PACKAGE}
		return 1
	fi

    new_version=$(/usr/bin/rpm -qip ${rpm_package}  | grep "Version" )
    installed_version=$(/usr/bin/rpm -qi zyWAF   | grep "Version" )
    new_release=$(/usr/bin/rpm -qip ${rpm_package}  | grep "Release" )
    installed_release=$(/usr/bin/rpm -qi zyWAF | grep "Release" )
    new_info=${new_version}${new_release}
    installed_info=${installed_version}${installed_release}

    if [ "${new_info}" \> "${installed_info}" ];then
        /usr/bin/echo ${VALID_PACKAGE}
        return 0
    else
      /usr/bin/echo ${SAME_OLDER_VERSION}
        return 1
  fi
}

stop_service()
{
	/usr/bin/echo "stop service" >> /tmp/${file_name}
	#/usr/bin/systemctl stop zywaf 
	/etc/init.d/zywaf stop
}

uninstall_rpm()
{

	/usr/bin/echo "uninstall rpm" >> /tmp/${file_name}
	/usr/bin/rpm -q zyWAF-debuginfo &&  /usr/bin/rpm -e zyWAF-debuginfo
 	/usr/bin/rpm -q zyWAF &&  /usr/bin/rpm -e zyWAF 
}

install_rpm()
{
	/usr/bin/echo "install rpm" >> /tmp/${file_name}
	/usr/bin/rpm -i ${rpm_package}
	ret=$?
	if [ ${ret} == 0 ]; then
		return 0
	else
		return ${ret}
	fi
}
restart_service()
{
	/usr/bin/echo "restart service" >> /tmp/${file_name}
	/etc/init.d/zywaf restart
}

zywaf_upgrade()
{
	act=$1
	rpm_package=$2
	usage="Usage: ./zywaf_upgrade.sh  [check|upgrade]  zyWAF-x.x.x-xxxx.x86_64.rpm"
	if [ -z "${act}"  -o  -z "${rpm_package}" ]; 
	then
		echo ${usage}
		exit 2
	fi 

	if ! [ "${act}" == "check" -o "${act}" == "upgrade" ];then
		echo ${usage}
		exit 3
	fi


	if [ ${act} == "check" ]; then
		/usr/bin/echo "start check" > /tmp/${file_name}
		validation || return 1
		return  0
	fi

	if [ ${act} == "upgrade" ]; then
	    if [ `id -u` -ne 0 ];then
		/usr/bin/echo ${NOT_ROOT} > /tmp/${file_name}
	    fi
		/usr/bin/echo "start upgrade" > /tmp/${file_name}
		validation ||  exit 1
		stop_service && 
		sleep 3 &&
		uninstall_rpm &&
		sleep 3 &&
		install_rpm &&
		sleep 3 &&
		/usr/bin/systemctl daemon-reload
		sleep 3 
		restart_service 
		ret=$?
		[[ ${ret} == "0" ]] && echo ${UPGRADE_SUC} >> /tmp/${file_name}
		/usr/bin/echo "upgrade finished ${ret}" >> /tmp/${file_name}
		exit ${ret}
	fi
}



zywaf_upgrade "upgrade" ${rpm_file}


