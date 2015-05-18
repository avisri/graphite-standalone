#!/bin/bash
#configures
#		/opt/graphite/conf/graphite.wsgi
#		/opt/graphite/conf/storage-schemas.conf
#		/opt/graphite/conf/carbon.conf
#		/opt/graphite/conf/storage-aggregation.conf
#		/opt/graphite/webapp/graphite/local_settings.py		

echo "-------configuring grpahite.wsgi--------"
cat > /opt/graphite/conf/graphite.wsgi <<EOF
import os, sys
sys.path.append('/opt/graphite/webapp')
os.environ['DJANGO_SETTINGS_MODULE'] = 'graphite.settings'

import django.core.handlers.wsgi

application = django.core.handlers.wsgi.WSGIHandler()

# READ THIS
# Initializing the search index can be very expensive, please include
# the WSGIImportScript directive pointing to this script in your vhost
# config to ensure the index is preloaded before any requests are handed
# to the process.
from graphite.logger import log
log.info("graphite.wsgi - pid %d - reloading search index" % os.getpid())
import graphite.metrics.search
EOF

echo  "------Configuring whisper-----"
cat > /opt/graphite/conf/storage-schemas.conf <<EOF
# Schema definitions for whisper files. Entries are scanned in order,
# and first match wins.
[default]
pattern = .*
retentions = 1s:30m,1m:1d,5m:2y
EOF

echo "------configuring carbon------" 
cat > /opt/graphite/conf/carbon.conf <<EOF
[cache]
ENABLE_LOGROTATION = True
USER =
MAX_CACHE_SIZE = inf
MAX_UPDATES_PER_SECOND = 500
MAX_CREATES_PER_MINUTE = 50
LINE_RECEIVER_INTERFACE = 0.0.0.0
LINE_RECEIVER_PORT = 2003
ENABLE_UDP_LISTENER = False
UDP_RECEIVER_INTERFACE = 0.0.0.0
UDP_RECEIVER_PORT = 2003
PICKLE_RECEIVER_INTERFACE = 0.0.0.0
PICKLE_RECEIVER_PORT = 2004
LOG_LISTENER_CONNECTIONS = True
USE_INSECURE_UNPICKLER = False
CACHE_QUERY_INTERFACE = 0.0.0.0
CACHE_QUERY_PORT = 7002
USE_FLOW_CONTROL = True
LOG_UPDATES = False
LOG_CACHE_HITS = False
LOG_CACHE_QUEUE_SORTS = True
CACHE_WRITE_STRATEGY = sorted
WHISPER_AUTOFLUSH = False
WHISPER_FALLOCATE_CREATE = True
CARBON_METRIC_INTERVAL = 60
ENABLE_AMQP = False

[relay]
ENABLE_LOGROTATION = True
USER =
LINE_RECEIVER_INTERFACE = 0.0.0.0
LINE_RECEIVER_PORT = 2013
PICKLE_RECEIVER_INTERFACE = 0.0.0.0
PICKLE_RECEIVER_PORT = 2014
LOG_LISTENER_CONNECTIONS = True
RELAY_METHOD = rules
REPLICATION_FACTOR = 1
DESTINATIONS = 127.0.0.1:2004
MAX_DATAPOINTS_PER_MESSAGE = 500
MAX_QUEUE_SIZE = 10000
USE_FLOW_CONTROL = True
CARBON_METRIC_INTERVAL = 60

[aggregator]
ENABLE_LOGROTATION = True
USER =
LINE_RECEIVER_INTERFACE = 0.0.0.0
LINE_RECEIVER_PORT = 2023
PICKLE_RECEIVER_INTERFACE = 0.0.0.0
PICKLE_RECEIVER_PORT = 2024
LOG_LISTENER_CONNECTIONS = True
FORWARD_ALL = True
DESTINATIONS = 127.0.0.1:2004
REPLICATION_FACTOR = 1
MAX_QUEUE_SIZE = 10000
USE_FLOW_CONTROL = True
MAX_DATAPOINTS_PER_MESSAGE = 500
MAX_AGGREGATION_INTERVALS = 5
CARBON_METRIC_INTERVAL = 60
EOF

echo "-------configuring storage-aggregations.conf--------- " 
cat > /opt/graphite/conf/storage-aggregation.conf <<EOF
[min]
pattern = \.min$
xFilesFactor = 0.1
aggregationMethod = min

[max]
pattern = \.max$
xFilesFactor = 0.1
aggregationMethod = max

[sum]
pattern = \.count$
xFilesFactor = 0
aggregationMethod = sum

[default_average]
pattern = .*
xFilesFactor = 0.5
aggregationMethod = average
EOF

echo '------ configuring /opt/graphite/webapp/graphite/local_settings.py --- ' 
cat > /opt/graphite/webapp/graphite/local_settings.py <<EOF
SECRET_KEY = 'UNSAFE_DEFAULT'

TIME_ZONE = 'GMT'

#DOCUMENTATION_URL = "http://graphite.readthedocs.org/"

# Logging
#LOG_RENDERING_PERFORMANCE = True
#LOG_CACHE_PERFORMANCE = True
#LOG_METRIC_ACCESS = True

# Enable full debug page display on exceptions (Internal Server Error pages)
#DEBUG = True

# If using RRD files and rrdcached, set to the address or socket of the daemon
#FLUSHRRDCACHED = 'unix:/var/run/rrdcached.sock'

# Change only GRAPHITE_ROOT if your install is merely shifted from /opt/graphite
# to somewhere else
#GRAPHITE_ROOT = '/opt/graphite'

# Most installs done outside of a separate tree such as /opt/graphite will only
# need to change these three settings. Note that the default settings for each
# of these is relative to GRAPHITE_ROOT
#CONF_DIR = '/opt/graphite/conf'
#STORAGE_DIR = '/opt/graphite/storage'
#CONTENT_DIR = '/opt/graphite/webapp/content'

# To further or fully customize the paths, modify the following. Note that the
# default settings for each of these are relative to CONF_DIR and STORAGE_DIR
#
## Webapp config files
#DASHBOARD_CONF = '/opt/graphite/conf/dashboard.conf'
#GRAPHTEMPLATES_CONF = '/opt/graphite/conf/graphTemplates.conf'

## Data directories
# NOTE: If any directory is unreadable in DATA_DIRS it will break metric browsing
#WHISPER_DIR = '/opt/graphite/storage/whisper'
#RRD_DIR = '/opt/graphite/storage/rrd'
#DATA_DIRS = [WHISPER_DIR, RRD_DIR] # Default: set from the above variables
#LOG_DIR = '/opt/graphite/storage/log/webapp'
#INDEX_FILE = '/opt/graphite/storage/index'  # Search index file


DATABASES = {
   'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'graphite',
        'USER': 'graphite',
        'PASSWORD': 'graphite',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
EOF
