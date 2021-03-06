#!/bin/bash 

echo "-------Configure postgres to allow graphite user:"
echo " ----install postgres packages -----"
yum -y install postgresql postgresql-server postgresql-devel
service postgresql initdb
grep "listen_addresses = '0.0.0.0'" /var/lib/pgsql/data/postgresql.conf
if [[ $? -ne 0 ]]; then
  echo "listen_addresses = '0.0.0.0'" >> /var/lib/pgsql/data/postgresql.conf
fi
service postgresql start || echo "db already started!"
sudo -u postgres psql template1 <<END
create user graphite with password 'graphite';
create database graphite with owner graphite;
END

echo " ------- Modify PostgreSQL "Client Authentication" -- use md5:"

cat > /var/lib/pgsql/data/pg_hba.conf <<EOM
# "local" is for Unix domain socket connections only
local   all         all                               md5
# IPv4 local connections:
host    all         all         127.0.0.1/32          md5
# IPv6 local connections:
host    all         all         ::1/128               md5
EOM

echo ------validate the db -----
sudo -u postgres -- psql -Ugraphite<<END
\l
\dt
END

