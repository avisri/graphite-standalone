#!/bin/bash

tmp=`mktemp`
sha='fbd86f1c9e397672823bb570ffb3a7495ffd7e83  perl-rrdtool-1.4.7-1.el6.rfx.x86_64.rpm
9e05db68809fe9be23099d8b437d6ec487017820  rrdtool-1.4.7-1.el6.rfx.x86_64.rpm
722429b4921e0c412fae72d294938ca5e3c30374  rrdtool-devel-1.4.7-1.el6.rfx.x86_64.rpm'

version="1.4.7-1" ;
cd <mp
wget http://pkgs.repoforge.org/rrdtool/{rrdtool,rrdtool-devel<Plug>PeepOpenerl-rrdtool}-$version.el6.rfx.x86_64.rpm
echo ' ---validating checksum -- '
chksum=`sha1sum *rrdtool*.rpm`
[ "$chksum" !=  "$sha" ] && echo ' Checksum not macthing .. exiting' && exit 1
echo ' ---validated checksum -- '
echo "$chksum"
echo ' --- installing with yum --'
yum -y localinstall  <mp/*rrd*.rpm>>
