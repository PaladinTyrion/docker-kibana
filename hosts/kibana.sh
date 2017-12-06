#!/bin/bash

# create dir
mkdir -p /data0/elk/kibana
chmod -R +x /data0/elk

### create groups && users
# create kibana user
id "kibana" >& /dev/null
if [ $? -ne 0 ]
then
    groupadd -r kibana -g 443
    useradd -r -s /usr/sbin/nologin -c "Kibana service user" -u 443 -g kibana kibana
fi

# chown groups && users
chown -R kibana:kibana /data0/elk/kibana
