#!/bin/bash

set -o errexit
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

stage=""
no_of_stages=`grep -c "stage=" $0`
stage_count=0
message()
{
	((stage_count++))
	echo "$*" | sed -e "s#^#[ `date` ] (STAGE:$stage_count/$no_of_stages) < $stage >   #"
	cont
 	return $?
}

installs=( 				\
bitmap                  \
bitmap-fonts-compat     \
Django14                \
epel-release            \
gcc                     \
gcc-c++                 \
git                     \
mlocate                 \
mod_wsgi                \
MySQL-python            \
pycairo                 \
pyOpenSSL               \
python                  \
python-crypto           \
python-devel            \
python-django15         \
python-django-tagging   \
python-ldap             \
python-memcached        \
python-psycopg2         \
python-setuptools       \
python-sqlite2          \
python-twisted-web      \
python-txamqp           \
python-zope-filesystem  \
python-zope-interface   \
pytz                    \
vim-enhanced            \
zlib-static             \
)

stage="YUM INSTALL"
message "---- Installing ${installs[*]},------" && {
	#echo "${installs[*]}" | xargs sudo yum -q -y install || true
	echo "${installs[*]}" | xargs -n1 sudo rpm -q --last
	message "---- Press any key to continue --- "
	read
}

stage="GIT CLONE"
message '
#Requirements
   Graphite requires:
     * python2.4 or greater
     * pycairo (with PNG backend support)
     * mod_python
     * django
     * python-ldap (optional - needed for ldap-based webapp
       authentication)
     * python-memcached (optional - needed for webapp caching, big
       performance boost)
     * python-sqlite2 (optional - a django-supported database module is
       required)
     * bitmap and bitmap-fonts required on some systems, notably Red Hat

 You can also use the latest source by checking it out with git:
 Installing  from Mastoer (unstable/alpha) branch
' && {
	git clone https://github.com/graphite-project/graphite-web.git
	git clone https://github.com/graphite-project/carbon.git
	git clone https://github.com/graphite-project/whisper.git
	# 0.9.x (stable) branch
	cd graphite-web
	git checkout 0.9.x
	cd ..
	cd carbon
	git checkout 0.9.x
	cd ..
	cd whisper
	git checkout 0.9.x
	cd ..
}

stage="INSTALL WHISPER"
message "----------Install Whisper------------- " && {
	pushd whisper
	sudo python setup.py install
	popd
}

stage="INSTALL CARBON"
message "-------Install Carbon--------------------
By default, everything will be installed in /opt/graphite"  && {
	#   To install carbon:
	mkdir -p /opt/graphite/conf
	pushd carbon
	python setup.py install
	popd
}

stage="CONFIGURE CARBON"
message '
   The default values in the examples are sane, but it is strongly
   recommended to consider how much data you would like to retain. By
   default, it will be saved for 1 day in 1 minute intervals. This is set
   in the whisper files individually, and changing the value here will not
   alter existing metrics. A conversion script shipped with Whisper
   (whisper-resize.py) can be used to change these later. Many people will
   want to store more than one days worth of data. If you think that you
   may want to track trends week over week, month over month or year over
   year, you may want to store 13 months (1 year + 1 month) or perhaps
   even 2 - 3 years worth of data. If you want to learn more about data
   retentions, please click [31]here.

   Here is an example of the 13-month retention example (giving you a
   month of overlap when comparing metrics year-over-year):

   Note: Priority is not used. **
   Rules are applied in the order they appear in the file**
[everything_1min_13months]
priority = 100
pattern = .*
retentions = 1m:395d

   Be sure to replace the entire [everything_1min_1day] section with this
   example.

Configure Carbon 
' && {
	pushd /opt/graphite/conf
	cp carbon.conf.example carbon.conf
	cp storage-schemas.conf.example storage-schemas.conf
	popd
}

stage="INSTALL TXAMPQ"
message " Ehhh .. Need to install a pip for resolving deps 
	 Src : https://pypi.python.org/pypi/txAMQP " && {
	yum -y install python-pip
	pip install txamqp
}
	 

stage="CHECK GRAPHITE WEB DEPS"
message  "----- Check deps for  the Graphite webapp ----
This is the frontend / webapp that renders the images"   && {
	pushd graphite-web
	python check-dependencies.py
	popd
}


stage="INSTALL GRAPHITE WEB"
message "
   Use your distribution's package manager or any other means to install
   the required software.
   Once the dependencies are met, install Graphite:
" && {
	pushd graphite-web
	python setup.py install
	popd
}

stage="CONFIGURE HTTPD FOR GRAPHITE" 
message "-------Configure Apache-------
   There is an example example-graphite-vhost.conf file in the examples
   directory of the graphite web source code. You can use this to
   configure apache. Different distributions have different ways of
   configuring Apache. Please refer to your distribution's documentation
   on the subject.

   For example, Ubuntu uses /etc/apache2/sites-available and
   sites-enabled/ to handle this (A symlink from sites-enabled/ to
   sites-available/ would be used after placing the file in
   sites-available/).

   Others use an Include directive in the httpd.conf file like this:
# This goes in httpd.conf
Include /usr/local/apache2/conf/vhosts.d/*.conf

   The configuration files must then all be added to
   /usr/local/apache2/conf/vhosts.d/.

   Still others may not help handle this at all and you must add the
   configuration to your http.conf file directly.

   Graphite will be in the DocumentRoot of your webserver, and will not
   allow you to access plain-HTML in subdirectories without addition
   configuration. You may want to edit the example-graphite-vhosts.conf
   file to change port numbers or use additional "SetHandler None"
   directives to allow access to other directories.
" && {
	./configure_graphite_httpd.sh
	sudo service httpd restart
}

stage="CONFIGURE POSTGRES & INTEGRATE GRAPHITE WEB-->DB"
message " ---------Initial Database Creation------------
   You must tell Django to create the database tables used by the graphite
   webapp. This is very straight forward, especially if you are using the
   default sqlite setup.

   NOTE: If you are using a custom database backend (other than sqlite)
   you must first create a
   $GRAPHITE_ROOT/webapp/graphite/local_settings.py file that overrides
   the database related settings from settings.py. Use
   $GRAPHITE_ROOT/webapp/graphite/local_settings.py.example as a template.

   Assuming you are using the default setup, you should be able to create
   theo database with the following commands:
" && { 
	./configure_postgres.sh
	echo "-------Initialize Django DB creation (requires configuring /opt/graphite/webapp/graphite/local_settings.py): "
	pushd /opt/graphite/webapp/graphite
	python manage.py syncdb --noinput
	popd
}

stage="CONFIGURE GRAPHITE WEB"
message "
   This varies widely among different distributions.

   If you use a backend such as mysql or postgres, the DATABASE_USER you
   create in your local_settings.py must have permission to create tables
   under the database named by DATABASE_NAME.

   Restart apache and you should see the graphite webapp on the main page.
   If you encounter problems, you can increase the verbosity of error by
   creating a local_settings file.
   CONFIGURE GRAPHITE WEB
" && { 
	#cd /opt/graphite/webapp/graphite
	#cp local_settings.py.example local_settings.py
	#Uncomment the following line in
	#/opt/graphite/webapp/graphite/local_settings.py
	# DEBUG = True
	./configure_graphite_web.sh
}

stage="CONFIGURE CARBON CACHE"
message "
   Also remember that the apache logs for the graphite webapp in the
   graphite-example-vhost.conf are in /opt/graphite/storage/logs/
   Start Carbon (the data aggregator)
" && {
	#pushd /opt/graphite/
	#./bin/carbon-cache.py start
	#popd
	./configure_etc_init_d_carbon_cache.sh
	chmod +x /etc/init.d/carbon-cache
	service carbon-cache start
}

stage="INSTALL COLLECTD"
message "
Next Steps
   Now you have finished installing graphite, the next thing to do is put
   some real data into it. This is accomplished by sending it some data as
   demonstrated in the included
   ./examples/example-client.py

With this we are done with  installs and configure 
- install and  configure collectd 
- configure graphite
	- httpd
	- carbon cache
-Setup some /etc/init.d scripts for 
	- carbon cache

LAST : We are ready to install collectd using source ! 

" && {
	./install_collectd.sh
}

stage="FINAL RESTARTS"
message "Final recursive  chowns and  Restart all " && { 
	chown -R apache:apache /opt/graphite/storage/
	chcon -R -h -t httpd_sys_content_t /opt/graphite/storage
	service postgresql 	restart
	service carbon-cache 	restart
	service httpd	 	restart
	service collectd 	restart
}

