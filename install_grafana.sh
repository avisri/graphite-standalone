#!/bin/bash

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


yum install lynx -y
temp=`mktemp`
cd $tmp
version="2.1.2-1"
sha="091a6bfecb4054adb78b424681464152ddbd5402 grafana-2.1.2-1.x86_64.rpm"
lynx --listonly -dump http://grafana.org/download/ | grep rpm | awk '{print $NF}'|  grep $version | xargs  wget 
chksum=`sha1sum grafana-*.rpm` 
#[ "$chksum" != "$sha" ] && echo -e " Checksum ( $chksum  \n $sha)dont match .... exiting ... " && exit -1
yum localinstall grafana-*.rpm -y

systemctl daemon-reload grafana-server
systemctl enable grafana-server
systemctl start  grafana-server
cd -
rm -rf $tmp

