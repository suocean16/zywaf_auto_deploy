#!/usr/bin/bash
	
echo -e "Usage:\n$0 username password build-version web_ip, web_port, zywaf_port,domain [full|auto]"\
	"\n\t\tusername: zyprotect ftp username"\
	"\n\t\tpassword: zyprotect ftp password"\
	"\n\t\tusername: zyprotect build version eg: 1802, 4017"\
	"\n\t\tweb_ip: the Web Site IP address"\
	"\n\t\tweb_port: the Web Site listening port"\
	"\n\t\tdomain: the Web Site domain name"\
	"\n\t\tfull/auto: full: it will remove all WAF file and install whole files."\
	"\n\t\t           auto: it only reinstall when their is a old zyWAF installation."
