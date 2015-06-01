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
	systemctl $cmd $service.service
done

[ "$cmd" != "status" ] && {
	for service in ${order[*]}
	do
		echo Staus of $service after $cmd-----
		systemctl status $service.service  | sed -e "s/^/[ $service ]/"  
		echo ---------------------------------
	done | tee /tmp/c
	grep -i  success  /tmp/c
} 

