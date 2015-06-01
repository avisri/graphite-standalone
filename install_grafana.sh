#!/bin/bash

   lynx --listonly -dump http://grafana.org/download/ | grep rpm | awk '{print $NF}'| sort -n | tail -1 | xargs rpm  -Uvh
   sudo /bin/systemctl daemon-reload
   sudo /bin/systemctl enable grafana-server.service
   sudo /bin/systemctl start  grafana-server.service

