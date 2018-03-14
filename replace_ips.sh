#!/bin/bash
# author: paladintyrion

#### start

kibana_conf_file="${KIBANA_HOME}/config/kibana.yml"

if [ ! -z "$ES_IP" ]; then
  es_ip="$ES_IP"
fi

if [ ! -z "$ELASTALERT_IP" ]; then
  elastalert_ip="$ELASTALERT_IP"
fi

##### replace words
es_addr="\"http://"${es_ip}":9200\""

##### modify the all configure

if [ ! -z ${es_ip} ]; then
  # replace kibana configure *.yml elasticsearch.url
  sed -i -e "s%^elasticsearch.url:.*$%elasticsearch.url: ${es_addr}%g" ${kibana_conf_file}
fi

if [ ! -z ${elastalert_ip} ]; then
  # replace kibana configure *.yml elasticsearch.url
  sed -i -e "s%^elastalert.serverHost:.*$%elastalert.serverHost: \"${elastalert_ip}\"%g" ${kibana_conf_file}
fi
