#!/bin/bash

my_pid=$$
function cont()
{
	echo "continue (y/n/s(kip)) ?"
	read a 
	a=`echo $a| tr '[A-Z]' '[a-z]' `
	[ "$a" == "n" ]  && exit 1 
	[ "$a" == "s" ]  && return 1

}

message()
{
	echo "$*" | sed -e "s/^/[ `date` ]   /"
	cont
 	return $?	
}

installs=( 			\
		epel-release	\
		mlocate		\
		git		\
		vim-enhanced  	\
		python 		\
		pycairo  	\
		mod_wsgi	\
		python-django	\
)

message "---- Installing ${installs[*]},------" && {
	sudo yum -y install "${installs[*]}"
}

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
	git clone https://github.com/graphite-project/graphite-web.gi
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

message "----------Install Whisper------------- " && {
	pushd whisper
	sudo python setup.py install
	popd
}

message "-------Install Carbon--------------------"
message "By default, everything will be installed in /opt/graphite"  && {

	#   To install carbon:
	mkdir -p /opt/graphite/conf
	pushd
	python setup.py install
	popd
}

message "Configure Carbon"

pushd /opt/graphite/conf
cp carbon.conf.example carbon.conf
cp storage-schemas.conf.example storage-schemas.conf

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
'

message  "----- Configure the Graphite webapp ----"
message  "This is the frontend / webapp that renders the images"
pushd graphite-web
python check-dependencies.py
popd


message "
   Use your distribution's package manager or any other means to install
   the required software.
   Once the dependencies are met, install Graphite:
"

pushd graphite-web
python setup.py install
popd

message -------Configure Apache-------

message "
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
"

sudo /etc/init.d/httpd reload

message "
Initial Database Creation

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
"


message"
   You will be prompted to create an admin user; most people will want to
   do this.

   Now you must change ownership of the database file to the same user
   that owns the Apache processes.
   If your distribution has apache run as user 'nobody':
"
cd /opt/graphite/webapp/graphite
sudo python manage.py syncdb
sudo chown nobody:nobody /opt/graphite/storage/graphite.db

message "
   This varies widely among different distributions.

   If you use a backend such as mysql or postgres, the DATABASE_USER you
   create in your local_settings.py must have permission to create tables
   under the database named by DATABASE_NAME.

   Restart apache and you should see the graphite webapp on the main page.
   If you encounter problems, you can increase the verbosity of error by
   creating a local_settings file.
"
cd /opt/graphite/webapp/graphite
cp local_settings.py.example local_settings.py


message "
   Uncomment the following line in
   /opt/graphite/webapp/graphite/local_settings.py
# DEBUG = True
"

message "
   Also remember that the apache logs for the graphite webapp in the
   graphite-example-vhost.conf are in /opt/graphite/storage/logs/

   Start Carbon (the data aggregator)
"
cd /opt/graphite/
./bin/carbon-cache.py start

message "Next Steps

   Now you have finished installing graphite, the next thing to do is put
   some real data into it. This is accomplished by sending it some data as
   demonstrated in the included
   ./examples/example-client.py
"

