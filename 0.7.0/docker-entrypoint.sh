#!/bin/sh
#
# start script for the nimmis/consul container
#
# (c) nimmis <kjell.havneskold@gmail.com>
#

# get local ip
NETWORK_ADDR=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

# handle bootstap expected hosts
BOOTSTRAP_EXPECT=${BOOTSTRAP_EXPECT:-1}

# set bind address
BIND_ADDR=${BIND_ADDR:-$NETWORK_ADDR}

# set join address if defined
if [ -n "$2" ]; then
  JOIN_IP=$2
fi

# get hostname of host
HOSTNAME=$(hostname)

#
# show help screen 
#

show_help() {
  echo "ERROR: $1"
  echo
  echo "start command with"
  echo "server [<join address>] to run a consul server"
  echo "agent  <join address>   to run a consul agent"
  echo "reload                  to run consul with previous saved settings"
  exit 1
}

#
# write configuration for the agent
#

write_agent_config() {

cat > /data/agent/conf.d/00consul-agent.json  <<EOF
{
  "node_name": "$HOSTNAME",
  "datacenter": "$DATACENTER",
  "data_dir": "/data/agent",
  "log_level": "$LOG_LEVEL",
  "bind_addr": "$BIND_ADDR",
  "dns_config": {
                "allow_stale": true,
                "max_stale": "1s"
  		},
  "start_join": ["$JOIN_IP"]
}
EOF

}

#
# write configuration for the server
#

write_server_config() {

cat > /data/server/conf.d/00consul-server.json <<EOF
{
  "server": true,
  "node_name": "$HOSTNAME",
  "datacenter": "$DATACENTER",
  "data_dir": "/data/server",
  "log_level": "$LOG_LEVEL",
  "bind_addr": "$BIND_ADDR",
  "client_addr": "0.0.0.0",
  "dns_config": { "allow_stale": false },
  "ui": true,
  "bootstrap_expect": $BOOTSTRAP_EXPECT
EOF

if [ -z $JOIN_IP ]; then
  echo "}" >> /data/server/conf.d/00consul-server.json 
else
  printf ",\n  \"start_join\": [\"%s\"]\n}" $JOIN_IP >>  /data/server/conf.d/00consul-server.json
fi

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

      mkdir -p /data/agent/conf.d/

      # agent requiers a join address

      if [ -z $JOIN_IP ]; then
        show_help "Join address missing"
      fi

      write_agent_config

      save_state agent

      run_agent

}

#
# prepare and run as server
#

do_run_server() {

      mkdir -p /data/server/conf.d/

      write_server_config

      save_state server 

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

if [ -n "$1" ]; then

  case $1 in
    agent)
      do_run_agent
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
 
