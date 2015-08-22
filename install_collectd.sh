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

message " Install/reinstall  collectd with rrd-tool and graphite write support "  && {
	grep -q -i 'release 6' /etc/*-release  &&  ./install-rhel6-rrdtool.sh 
	cd /opt
	version="5.5.0"
	date=`date +%s`
	sha="847684cf5c10de1dc34145078af3fcf6e0d168ba98c14f1343b1062a4b569e88"
	rm -f collectd-${version}.tar.bgz
	wget https://collectd.org/files/collectd-${version}.tar.bz2 
	cksum=`sha256sum collectd-${version}.tar.bz2| awk '{print $1}'`
	[ "$sha" != "$cksum" ] && echo "checksum is not matching after download from source.. exiting "  && exit 1
	mv collectd-${version} collectd-${version}.bak.$date 
	tar jxf collectd-${version}.tar.bz2 
	cd collectd-${version}
	pwd
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
	cp -v contrib/redhat/init.d-collectd /etc/init.d/collectd
	chmod 755 /etc/init.d/collectd
	chown root:root /etc/init.d/collectd
	/etc/init.d/collectd start
	chkconfig collectd on
}

message "
Configure collectd to write system metrics to graphite by editing /etc/collectd.conf and adding the following lines:" && { 
mkdir -p  /etc/collect.d/

cat > /etc/collectd.d/unixsock.conf <<EOF
LoadPlugin unixsock
<Plugin unixsock>
	SocketFile "/usr/var/run/collectd-unixsock"
	SocketGroup "collectd"
	SocketPerms "0660"
</Plugin>
EOF

cat > /etc/collectd.d/graphite-collectd.conf <<EOF
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

	echo '

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
LoadPlugin uptime
LoadPlugin users
LoadPlugin uuid


Include "/etc/collectd.d/*.conf"

' > /etc/collectd.conf 
	/etc/init.d/collectd restart
}




