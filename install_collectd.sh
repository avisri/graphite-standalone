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
collectd-ping	 	 \
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
#	./configure 	--prefix=/usr 		\
#		   	--sysconfdir=/etc 	\
#			--localstatedir=/var 	\
#			--libdir=/usr/lib 	\
#			--mandir=/usr/share/man \
#			--enable-cpu 		\
#			--enable-curl 		\
#			--enable-df 		\
#			--enable-exec 		\
#			--enable-load 		\
#			--enable-logfile 	\
#			--enable-memory 	\
#			--enable-network 	\
#			--enable-nginx 		\
#			--enable-syslog  	\
#			--enable-rrdtool 	\
#			--enable-uptime 	\
#			--enable-tcpconn	\
#			--enable-iptables	\
#			--enable-processes	\
#			--enable-ping		\
#			--enable-all		\
#			--enable-write_graphite
	./configure
	make
	make install
	#statically link some so like ping
	ln -s /usr/lib64/collectd/iptables.so  /usr/lib/collectd
	ln -s /usr/lib64/collectd/ping.so  /usr/lib/collectd

	cp -v contrib/redhat/init.d-collectd /etc/init.d/collectd
	read
	chmod 755 /etc/init.d/collectd
	chown root:root /etc/init.d/collectd
	/etc/init.d/collectd start
	chkconfig collectd on
}

message "
Configure collectd to write system metrics to graphite by editing /etc/collectd.conf and adding the following lines:" && { 
mkdir -p  /etc/collect.d/
cd /etc/collect.d/

cat > unixsock.conf <<EOF
LoadPlugin unixsock
<Plugin unixsock>
	SocketFile "/var/run/collectd-unixsock"
	SocketGroup "collectd"
	SocketPerms "0660"
</Plugin>
EOF

cat >processes.conf <<EOF
LoadPlugin processes
<Plugin "processes">
	ProcessMatch "ossec-remoted" "ossec-remoted"
</Plugin>
EOF

cat >iostat.conf <<EOF
<LoadPlugin python>
    Globals true
</LoadPlugin>

<Plugin python>
    ModulePath "/usr/lib/collectd/plugins/python"
    Import "collectd_iostat_python"

    <Module collectd_iostat_python>
        Path "/usr/bin/iostat"
        Interval 2
        Count 2
        Verbose false
        NiceNames false
        PluginName collectd_iostat_python
    </Module>
</Plugin>
EOF

cat >iptables.conf <<EOF
#[root@sfm-eplog-ls001 ~]#  iptables -L -nvx    | egrep  'Chain|udp'
#Chain INPUT (policy DROP 507 packets, 52259 bytes)
#       0        0 ACCEPT     udp  --  *      *       10.128.11.30         0.0.0.0/0           udp dpt:161
#       0        0 ACCEPT     udp  --  *      *       10.1.34.15           0.0.0.0/0           udp dpt:161
#   23857  1192631 ACCEPT     udp  --  *      *       10.1.230.0/24        0.0.0.0/0           udp dpt:1514 /* udp_1514_10_1_230_accept */
#    1032   383264 ACCEPT     udp  --  *      *       10.1.0.0/16          0.0.0.0/0           udp dpt:1514 /* udp_1514_10_1_accept */
#       0        0 ACCEPT     udp  --  *      *       10.3.0.0/16          0.0.0.0/0           udp dpt:1514 /* udp_1514_10_3_accept */
#       0        0 ACCEPT     udp  --  *      *       0.0.0.0/0            0.0.0.0/0           udp dpt:1514 /* udp_1514_default_accept */
LoadPlugin iptables
<Plugin "iptables">
  Chain "filter" "INPUT" "udp_1514_10_1_230_accept"
  Chain "filter" "INPUT" "udp_1514_10_1_accept"
  Chain "filter" "INPUT" "udp_1514_10_3_accept"
  Chain "filter" "INPUT" "udp_1514_default_accept"
</Plugin>
EOF

cat > graphite-collectd.conf <<EOF
LoadPlugin processes
<Plugin "processes">
	ProcessMatch "ossec-remoted" "ossec-remoted"
</Plugin>
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

cd -

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
#LoadPlugin rrdtool
LoadPlugin uptime
LoadPlugin users
#LoadPlugin uuid
LoadPlugin tcpconns


Include "/etc/collectd.d/*.conf"

' > /etc/collectd.conf 
	/etc/init.d/collectd restart
}




