#!/bin/bash

my_pid=$$
function cont()
{
	echo "continue (y/n/s(kip)) ?"
	read a 
	a=`echo $a| tr '[A-Z]' '[a-z]' `
	[ "$a" == "n" ]  && exit 1 
	[ "$a" == "s" ]  && return 1
	[ "$a" == "y" ]  && return 0

}

message()
{
	echo "$*" | sed -e "s/^/[ `date` ]   /"
	cont
 	return $?
}

installs=( 		 \
gcc                      \
gcc-c++                  \
libgcrypt-devel          \
make                     \
perl                     \
perl-ExtUtils-CBuilder   \
perl-ExtUtils-Embed      \
perl-ExtUtils-MakeMaker  \
rrdtool                  \
rrdtool-devel            \
rrdtool-perl             \
)

message "---- Installing ${installs[*]},------" && {
	echo "${installs[*]}" | xargs sudo yum -y install
}

message " Install collectd with rrd-tool and graphite write support "  && {
	cd /opt
	curl -s -L http://collectd.org/files/collectd-5.4.0.tar.bz2 | tar jx
	cd collectd-5.4.0
	./configure 	--prefix=/usr 		\
		   	--sysconfdir=/etc 	\
			--localstatedir=/var 	\
			--libdir=/usr/lib 	\
			--mandir=/usr/share/man \
			--enable-cpu 		\
			--enable-curl 		\
			--enable-df 		\
			--enable-exec 		\
			--enable-load 		\
			--enable-logfile 	\
			--enable-memory 	\
			--enable-network 	\
			--enable-nginx 		\
			--enable-syslog  	\
			--enable-rrdtool 	\
			--enable-uptime 	\
			--enable-write_graphite
	make
	make install
	cp contrib/redhat/init.d-collectd /etc/init.d/collectd
	chmod 755 /etc/init.d/collectd
	chown root:root /etc/init.d/collectd
	/etc/init.d/collectd start
	chkconfig collectd on
}

message "
Configure collectd to write system metrics to graphite by editing /etc/collectd.conf and adding the following lines:" && { 
cat > /etc/collectd.conf <<EOF
LoadPlugin syslog

LoadPlugin "logfile"
<Plugin "logfile">
  LogLevel "info"
  File "/var/log/collectd.log"
  Timestamp true
</Plugin>

LoadPlugin cpu
LoadPlugin interface
LoadPlugin load
LoadPlugin memory
LoadPlugin rrdtool

LoadPlugin write_graphite
<Plugin "write_graphite">
 <Carbon>
   Host "127.0.0.1"
   Port "2003"
   Prefix "collectd."
   #Postfix ""
   Protocol "tcp"
   EscapeCharacter "_"
   SeparateInstances true
   StoreRates false
   AlwaysAppendDS false
 </Carbon>
</Plugin>
EOF
}

message "Restart collectd to start sending metrics to graphite" && {
	/etc/init.d/collectd restart
}




