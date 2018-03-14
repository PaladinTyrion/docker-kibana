docker run -d -it --net=host --privileged -p 5601:5601 --name kibana \
  -e ES_IP=0.0.0.0 \
  -e ELASTALERT_IP=0.0.0.0 \
  -v /data0/elk/kibana/log:/var/log/kibana \
  -v /data0/elk/kibana/tmp:/tmp/kibana \
  paladintyrion/kibana
