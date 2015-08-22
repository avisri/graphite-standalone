#!/bin/bash

cmd=${1:-start}

# this this start order of services
order=( 	\
postgresql 	\
carbon-cache	\
httpd		\
collectd	\
grafana-server 	\
)

#rhel6 still has service

systemctl()
{
	if which systemctl 2>/dev/null | grep -q systemctl
	then
		$0 $1 $2.service
	elif which service  2>/dev/null | grep -q /sbin/service 
	then
		service  $2 $1
	else
	   echo "System support for /etc/init.d scripts doesn't exist"
	fi
 	 	
}


[ "$cmd" == "stop" ] && {

	stop_order=""
	for service in $order
	do
	   stop_order="$service  $stop_order"
	done
	order=$stop_order
}

for service in ${order[*]}
do
	echo ${cmd}ing $service-----
	systemctl $cmd $service
done

[ "$cmd" != "status" ] && {
	for service in ${order[*]}
	do
		echo Staus of $service after $cmd-----
		systemctl status $service  | sed -e "s/^/[ $service ]/"  
		echo ---------------------------------
	done | tee /tmp/c
	grep -i  success  /tmp/c
} 

