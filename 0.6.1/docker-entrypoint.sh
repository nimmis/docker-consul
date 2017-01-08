#!/bin/sh
#
# start script for the nimmis/consul container
#
# (c) nimmis <kjell.havneskold@gmail.com>
#

# get local ip
NETWORK_ADDR=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

# handle bootstap expected hosts
# BOOTSTRAP_EXPECT=${BOOTSTRAP_EXPECT:-1}

# set bind address
BIND_ADDR=${BIND_ADDR:-$NETWORK_ADDR}

# set join address if defined
if [ -n "$2" ]; then
  JOIN_IP=$2
fi

# get hostname of host
HOSTNAME=$(hostname)

#
# show build info
#

show_build_info() {
  cat /etc/BUILDS/*
}

#
# show help screen 
#

show_help() {
  echo "ERROR: $1"
  echo
  echo "start command with"
  echo "server1                  to run a consul server, first/only server"
  echo "server <join address>    to run more consul servers"
  echo "agent  <join address>    to run a consul agent"
  echo "reload                   to run consul with previous saved settings"
  echo 
  exit 1
}

#
# generate base config file
#
# init_config <data dir>
#

init_config() {

CONFIG=$(cat <<EOF
{
  "node_name": "$HOSTNAME",
  "datacenter": "$DATACENTER",
  "data_dir": "$1",
  "log_level": "$LOG_LEVEL",
  "bind_addr": "$BIND_ADDR"
EOF
)

}

#
# init_add <key> <data>
#

init_add(){

CONFIG=${CONFIG}$(cat <<EOF
,
  "$1": $2
EOF
)

}

#
# write configuration for the agent
#

write_agent_config() {

  init_config "/data/agent"
  init_add dns_config '{ "allow_stale": true, "max_stale": "1s" }'
  init_add start_join "[\"$JOIN_IP\"]"
  CONFIG=${CONFIG}$(printf "\n}\n" )

  echo $CONFIG > /data/agent/conf.d/00consul-agent.json
}

#
# write configuration for the server
#

write_server_config() {

  init_config "/data/server"
  init_add server true
  init_add client_addr '"0.0.0.0"'
  init_add dns_config '{ "allow_stale": false }'
  init_add ui true

  if [ -n "$BOOTSTRAP_EXPECT" ]; then
    init_add bootstrap_expect $BOOTSTRAP_EXPECT
  fi

  if [ -n "$JOIN_IP" ]; then
    init_add start_join "[\"$JOIN_IP\"]"
  fi
  CONFIG=${CONFIG}$(printf "\n}\n" )

  echo $CONFIG > /data/server/conf.d/00consul-server.json
}


#
# save information for reload
#

save_state() {

  echo "RELOAD=$1" > /data/last_state

}

#
# run consul as an agent
#

run_agent() {

   /usr/local/bin/consul agent -config-dir=/data/agent/conf.d/ $OPTIONS
}

#
# run consul as a server
#

run_server() {

  /usr/local/bin/consul agent -config-dir=/data/server/conf.d/ $OPTIONS
}


#
# prepare and run as agent
#

do_run_agent() {

      # create directory for agent
      mkdir -p /data/agent/conf.d/

      # agent requiers a join address
      if [ -z $JOIN_IP ]; then
        show_help "Join address missing"
      fi

      # create the agent config file
      write_agent_config

      # save state
      save_state agent

      # run agent
      run_agent

}

#
# prepare and run as server
#

do_run_server() {

      # create directory for server
      mkdir -p /data/server/conf.d/

      # Either JOIN_IP or BOOTSTRAP_EXPECT must be defined
      if [ -z $JOIN_IP ]  &&  [ -z $BOOTSTRAP_EXPECT ]; then                                              
        show_help "Join address missing or BOOTSTRAP_EXPECT not defined"                                    
      fi   

      # create the server config file
      write_server_config

      # save state
      save_state server 
 
      # run server
      run_server

}

#
# prepare and run based on last_state
#

do_reload() {

      # check to see if information is saved
      if [ -f /data/last_state ]; then

        source /data/last_state

        case $RELOAD in
	  agent)
            run_agent
            ;;
          server)
            run_server
            ;;
          *)
            show_help "RELOAD variable wrong in /data/last_state"
        esac

        show_help "file /data/last_state missing"

      fi
}

#
# main 
#

show_build_info

if [ -n "$1" ]; then

  case $1 in
    agent)
      do_run_agent
      ;;
    
    server1)
      # setr expect to 1 if not set
      BOOTSTRAP_EXPECT=${BOOTSTRAP_EXPECT:-1}

      do_run_server
      ;;

    server) 
      do_run_server
      ;;

    reload)
      do_reload
      ;;

    *)
      show_help
      ;;

  esac

else

  show_help "Missing parameter(s)"

fi 
 
