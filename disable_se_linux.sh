#!/bin/bash 


check_se()
{
	getenforce
}

disable_se_for_this_session_only()
{
	setenforce 0 # Permissive
}

disable_se_and_reboot()
{
	perl -pi -e 's/SELINUX=(enforcing|permissive)/SELINUX=disabled/g' /etc/selinux/config 
	reboot
}

se()
{

	check_se | grep -v Disabled  && disable_se_for_this_session_only && disable_se_and_reboot
}

echo "This script will check the se status , if it is not disabled then it will 
disable it and reboot the machine. 
To continue press any key  
or
ctrl +c to stop now .
" 
read
se
echo "SELINUX is now: " `check_se`
