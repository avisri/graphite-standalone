#!/bin/bash 

#configures 
#		/etc/httpd/conf.d/graphite.conf

cat > /etc/httpd/conf.d/graphite.conf <<EOF
<IfModule !wsgi_module.c>
    LoadModule wsgi_module modules/mod_wsgi.so
</IfModule>

WSGISocketPrefix run/wsgi

<VirtualHost *:80>
        ServerName $(hostname -f)
        DocumentRoot "/opt/graphite/webapp"
        ErrorLog /var/log/httpd/graphite_error.log
        CustomLog /var/log/httpd/graphite_access.log common

        WSGIDaemonProcess graphite processes=5 threads=5 display-name='%{GROUP}' inactivity-timeout=120
        WSGIProcessGroup graphite
        WSGIApplicationGroup %{GLOBAL}
        WSGIImportScript /opt/graphite/conf/graphite.wsgi process-group=graphite application-group=%{GLOBAL}

        WSGIScriptAlias / /opt/graphite/conf/graphite.wsgi

        Alias /content/ /opt/graphite/webapp/content/
        <Location "/content/">
                SetHandler None
        </Location>

        Alias /media/ "@DJANGO_ROOT@/contrib/admin/media/"
        <Location "/media/">
                SetHandler None
        </Location>

        <Directory /opt/graphite/conf/>
                Order deny,allow
                Allow from all
        </Directory>

</VirtualHost>
EOF



