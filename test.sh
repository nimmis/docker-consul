#!/bin/sh

EXTERNAL_IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
DOCKER_IP=$(/sbin/ifconfig docker0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
CONTAINER_NAME="$1:$2"

create_container() {

  echo -n "Creating container ($CONTAINER_NAME).."

  CONTAINER=$(docker run -d -h consul-test -p $DOCKER_IP:53:8600/udp $CONTAINER_NAME server 2>&1)

  if [ "$?" = "0" ]; then
    echo "OK"
  else
    echo "FAIL:$CONTAINER"
    EXIT_STATUS=1
  fi

}

delete_container() {

  echo -n "Deleteing container.."

  RET=$(docker rm -f $CONTAINER)

  if [ "$?" = "0" ]; then
     echo "OK"
  else
     echo "FAIL:$RET"
     EXIT_STATUS=255
  fi

}

check_container_ip() {

  echo -n "Checking DNS.."

  DIG_IP=$(dig @$DOCKER_IP consul.service.consul | awk '/^consul.service.consul/{print $5}')

  if [ "$CONTAINER_IP" = "$DIG_IP" ]; then

    echo "OK" 

  else 

    echo "FAIL: CONTAINER_IP=$CONTAINER_IP DIG_IP=$DIG_IP\2"
    EXIT_STATUS=2
  fi

}

check_node_name() {


  echo -n  "Checking http node name lookup.."


  NODE=$(curl -s http://$CONTAINER_IP:8500/v1/catalog/nodes?pretty | awk '/Node/{print $2}' | sed 's/[\._",]//g')

  if [ "$NODE" = "consul-test" ]; then

    echo "OK" 

  else

    echo "FAIL: node name missmatch NODE=$NODE" 
    EXIT_STATUS=3

  fi

}

check_consul_service_status() {

  echo -n  "Checking http consul service status.."

  SERVICE=$(curl -s curl -s http://$CONTAINER_IP:8500/v1/health/service/consul?pretty | awk '/"Status":/{print $2}' | sed 's/[\._",]//g')

  if [ "$SERVICE" = "passing" ]; then

    echo "OK"

  else
 
    echo "FAIL: result=$SERVICE"
    EXIT_STATUS=4

  fi 

}

check_write_keystore() {

  echo -n "Write value to key store.."

  PUT_KV=$(curl -s -X PUT -d 'test_value' http://$CONTAINER_IP:8500/v1/kv/example)

  if [ "$PUT_KV" = "true" ]; then
    echo "OK"
  else
    echo "FAIL:$PUT_KV" 
    EXIT_STATUS=5
  fi

}

check_read_keystore() {

  echo -n "Read back value from key store.."

  GET_KV=$(curl -s -X GET http://$CONTAINER_IP:8500/v1/kv/example?pretty | awk '/"Value":/{print $2}' | sed 's/^"//' | sed 's/",$//' | base64 -d )

  if [ "$GET_KV" = "test_value" ]; then
    echo "OK"
  else
    echo "FAIL:$GET_KV"
  fi

}


EXIT_STATUS=0

create_container


if [ "$EXIT_STATUS" = "0" ]; then

  CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER)  

  echo -n  "Waitning for container to startup.."

  # give it enought time to startup
  sleep 10

  echo "OK"


  check_container_ip

  check_node_name

  check_consul_service_status

  check_write_keystore

  check_read_keystore

  if [ ! "$EXIT_STATUS" = "0" ]; then
    echo "---- log output from container ---"
    docker logs $CONTAINER
  fi  
  delete_container 

else

  echo "FAILED to start container: $CONTAINER"
  EXIT_STATUS=1

fi

exit $EXIT_STATUS
