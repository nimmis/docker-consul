# Consul

Consul is a tool for service discovery and configuration. Consul is
distributed, highly available, and extremely scalable.

Consul provides several key features:

* **Service Discovery** - Consul makes it simple for services to register
  themselves and to discover other services via a DNS or HTTP interface.
  External services such as SaaS providers can be registered as well.

* **Health Checking** - Health Checking enables Consul to quickly alert
  operators about any issues in a cluster. The integration with service
  discovery prevents routing traffic to unhealthy hosts and enables service
  level circuit breakers.

* **Key/Value Storage** - A flexible key/value store enables storing
  dynamic configuration, feature flagging, coordination, leader election and
  more. The simple HTTP API makes it easy to use anywhere.

* **Multi-Datacenter** - Consul is built to be datacenter aware, and can
  support any number of regions without complex configuration.

This docker container has many thing configure to make it easy to get running with Consul

## Start single server

	docker run -d -h node1 --name consul nimmis/consul server1
	
starts a single server with hostname **node1** with all ports only local accessable, use 

	CONSUL_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' consul)

to get the IP of the container.

You can see if i succeeded by looking at the output of the logs

	docker logs -f consul

will look something like this

```
==> WARNING: BootstrapExpect Mode is specified as 1; this is the same as Bootstrap mode.
==> WARNING: Bootstrap mode enabled! Do not enable unless necessary
==> Starting Consul agent...
==> Starting Consul agent RPC...
==> Consul agent running!
           Version: 'v0.7.2'
         Node name: 'ed1830c12a1d'
        Datacenter: 'dc'
            Server: true (bootstrap: true)
       Client Addr: 0.0.0.0 (HTTP: 8500, HTTPS: -1, DNS: 8600, RPC: 8400)
      Cluster Addr: 172.17.0.16 (LAN: 8301, WAN: 8302)
    Gossip encrypt: false, RPC-TLS: false, TLS-Incoming: false
             Atlas: <disabled>

==> Log data will now stream in as it occurs:

    2017/01/11 18:47:08 [INFO] raft: Initial configuration (index=1): [{Suffrage:Voter ID:172.17.0.16:8300 Address:172.17.0.16:8300}]
    2017/01/11 18:47:08 [INFO] raft: Node at 172.17.0.16:8300 [Follower] entering Follower state (Leader: "")
    2017/01/11 18:47:08 [INFO] serf: EventMemberJoin: ed1830c12a1d 172.17.0.16
    2017/01/11 18:47:08 [INFO] consul: Adding LAN server ed1830c12a1d (Addr: tcp/172.17.0.16:8300) (DC: dc)
    2017/01/11 18:47:08 [INFO] serf: EventMemberJoin: ed1830c12a1d.dc 172.17.0.16
    2017/01/11 18:47:08 [INFO] consul: Adding WAN server ed1830c12a1d.dc (Addr: tcp/172.17.0.16:8300) (DC: dc)
    2017/01/11 18:47:15 [ERR] agent: failed to sync remote state: No cluster leader
    2017/01/11 18:47:17 [WARN] raft: Heartbeat timeout from "" reached, starting election
    2017/01/11 18:47:17 [INFO] raft: Node at 172.17.0.16:8300 [Candidate] entering Candidate state in term 2
    2017/01/11 18:47:17 [INFO] raft: Election won. Tally: 1
    2017/01/11 18:47:17 [INFO] raft: Node at 172.17.0.16:8300 [Leader] entering Leader state
    2017/01/11 18:47:17 [INFO] consul: cluster leadership acquired
    2017/01/11 18:47:17 [INFO] consul: New leader elected: ed1830c12a1d
    2017/01/11 18:47:17 [INFO] consul: member 'ed1830c12a1d' joined, marking health alive
    2017/01/11 18:47:20 [INFO] agent: Synced service 'consul'
```

Use CTRL+C to abort

### use DNS to access consul

You can use DNS to get information about IP for services nodes running consul

#### Get service information

You can get information of witch IP and port a service is running from, to get IP query, -p 8600 because default DNS port on Consul is 8600

	dig @$CONSUL_IP -p 8600 consul.service.consul
	
should return something like

```
; <<>> DiG 9.10.3-P4-Ubuntu <<>> @172.17.0.16 -p 8600 consul.service.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 5163
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;consul.service.consul.		IN	A

;; ANSWER SECTION:
consul.service.consul.	0	IN	A	172.17.0.16

;; Query time: 0 msec
;; SERVER: 172.17.0.16#8600(172.17.0.16)
;; WHEN: Wed Jan 11 19:47:29 CET 2017
;; MSG SIZE  rcvd: 55
```

use SRV record to get port also

	dig @$CONSUL_IP -p 8600 consul.service.consul SRV

should return something like

```
; <<>> DiG 9.10.3-P4-Ubuntu <<>> @172.17.0.16 -p 8600 consul.service.consul SRV
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 37039
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;consul.service.consul.		IN	SRV

;; ANSWER SECTION:
consul.service.consul.	0	IN	SRV	1 1 8300 ed1830c12a1d.node.dc.consul.

;; ADDITIONAL SECTION:
ed1830c12a1d.node.dc.consul. 0	IN	A	172.17.0.16

;; Query time: 0 msec
;; SERVER: 172.17.0.16#8600(172.17.0.16)
;; WHEN: Wed Jan 11 19:56:29 CET 2017
;; MSG SIZE  rcvd: 96
```

## use HTTP to access consul

You can use HTTP to access information about services and nodes, output is in JSON

### Get all active consul nodes

to get all active nodes use

	curl -s http://$CONSUL_IP:8500/v1/catalog/nodes?pretty

return the following
```
[
    {
        "Node": "node1",
        "Address": "172.17.0.16",
        "TaggedAddresses": {
            "lan": "172.17.0.16",
            "wan": "172.17.0.16"
        },
        "CreateIndex": 4,
        "ModifyIndex": 5
    }
]
```

### Get all active consul services

the command to get all services

	curl -s http://$CONSUL_IP:8500/v1/catalog/services?pretty

the output looks like this

```
{
    "consul": []
}
```

### Get health status of node1

	curl -s curl -s http://$CONSUL_IP:8500/v1/health/node/node1?pretty

shows the health status of the node **node1**

```
[
    {
        "Node": "node1",
        "CheckID": "serfHealth",
        "Name": "Serf Health Status",
        "Status": "passing",
        "Notes": "",
        "Output": "Agent alive and reachable",
        "ServiceID": "",
        "ServiceName": "",
        "CreateIndex": 4,
        "ModifyIndex": 4
    }
]
```

### Get health status of consul service

	curl -s curl -s http://$CONSUL_IP:8500/v1/health/service/consul?pretty

ows the health status of the service **consul**

```
[
    {
        "Node": {
            "Node": "node1",
            "Address": "172.17.0.16",
            "TaggedAddresses": {
                "lan": "172.17.0.16",
                "wan": "172.17.0.16"
            },
            "CreateIndex": 4,
            "ModifyIndex": 5
        },
        "Service": {
            "ID": "consul",
            "Service": "consul",
            "Tags": [],
            "Address": "",
            "Port": 8300,
            "EnableTagOverride": false,
            "CreateIndex": 4,
            "ModifyIndex": 5
        },
        "Checks": [
            {
                "Node": "node1",
                "CheckID": "serfHealth",
                "Name": "Serf Health Status",
                "Status": "passing",
                "Notes": "",
                "Output": "Agent alive and reachable",
                "ServiceID": "",
                "ServiceName": "",
                "CreateIndex": 4,
                "ModifyIndex": 4
            }
        ]
    }
]
```

## The key/value store

This can be used to hold dynamic configuration, assist in service coordination, build leader election, and enable anything else a developer can think to build.

### Writing values to the key/value store

You can use curl to write values to the store, for example write the value **yellow** to the key **webcluster/status**

	curl -s -X PUT -d 'yellow' http://$CONSUL_IP:8500/v1/kv/webcluster/status

The command returns

	true

to indicate that it was succellful

### Reading values to the key/value store

You use the same notation for the URL as when writing the key exept using *-X GET*

	curl -s -X GET http://$CONSUL_IP:8500/v1/kv/webcluster/status?pretty

This is the output from the above command

```
[
    {
        "LockIndex": 0,
        "Key": "webcluster/status",
        "Flags": 0,
        "Value": "eWVsbG93",
        "CreateIndex": 113,
        "ModifyIndex": 113
    }
]
```

But the **Value** field does not show **yellow**, that's because it is base64 encoded, running the result through the base64 command give the correct information

	>echo "eWVsbG93" | base64 -d
	yellow


... more information to be added...


## Issues

If you have any problems with or questions about this image, please contact us by submitting a ticket through a [GitHub issue](https://github.com/nimmis/docker-consul/issues "GitHub issue")

1. Look to see if someone already filled the bug, if not add a new one.
2. Add a good title and description with the following information.
 - if possible an copy of the output from **cat /etc/BUILDS/*** from inside the container
 - any logs relevant for the problem
 - how the container was started (flags, environment variables, mounted volumes etc)
 - any other information that can be helpful

## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

## TAGs


The different version is determined with the TAG 

The available version are **nimmis/consul:< tag >** where tag is 

| Tag    | Consul version | size |
| ------ | -------------- | ---- |
| latest | latest/0.7.2 | [![](https://images.microbadger.com/badges/image/nimmis/consul.svg)](https://microbadger.com/images/nimmis/consul "Get your own image badge on microbadger.com") | 
| 0.7 | 0.7.2 | [![](https://images.microbadger.com/badges/image/nimmis/consul:0.7.svg)](https://microbadger.com/images/nimmis/consul:0.7 "Get your own image badge on microbadger.com") |
| 0.7.2 | 0.7.2 | [![](https://images.microbadger.com/badges/image/nimmis/consul:0.7.2.svg)](https://microbadger.com/images/nimmis/consul:0.7.2 "Get your own image badge on microbadger.com") |
| 0.7.1 | 0.7.1 | [![](https://images.microbadger.com/badges/image/nimmis/consul:0.7.1.svg)](https://microbadger.com/images/nimmis/consul:0.7.1 "Get your own image badge on microbadger.com") |
| 0.7.0 | 0.7.0 | [![](https://images.microbadger.com/badges/image/nimmis/consul:0.7.0.svg)](https://microbadger.com/images/nimmis/consul:0.7.0 "Get your own image badge on microbadger.com") |
| 0.6 | 0.6.4 | [![](https://images.microbadger.com/badges/image/nimmis/consul:0.6.svg)](https://microbadger.com/images/nimmis/consul:0.6 "Get your own image badge on microbadger.com") |
| 0.6.1 | 0.6.1 | [![](https://images.microbadger.com/badges/image/nimmis/consul:0.6.1.svg)](https://microbadger.com/images/nimmis/consul:0.6.1 "Get your own image badge on microbadger.com") |
| 0.6.2 | 0.6.2 | [![](https://images.microbadger.com/badges/image/nimmis/consul:0.6.2.svg)](https://microbadger.com/images/nimmis/consul:0.6.2 "Get your own image badge on microbadger.com") |
| 0.6.3 | 0.6.3 | [![](https://images.microbadger.com/badges/image/nimmis/consul:0.6.3.svg)](https://microbadger.com/images/nimmis/consul:0.6.3 "Get your own image badge on microbadger.com") |
| 0.6.4 | 0.6.4 | [![](https://images.microbadger.com/badges/image/nimmis/consul:0.6.4.svg)](https://microbadger.com/images/nimmis/consul:0.6.4 "Get your own image badge on microbadger.com") |

