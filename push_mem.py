#!/usr/bin/env python

import os
from prometheus_client import CollectorRegistry, Gauge, pushadd_to_gateway

mem_used = os.popen("free | awk '/Mem/{print $3}'")
node = os.popen("hostname")
mem_used_bytes = mem_used.read().strip()
act_node = node.read().strip().split('.')[0]
mem_used.close()
node.close()

registry = CollectorRegistry()

g = Gauge('Temp_Node_Memory_Used', 'Node memory used info', ['act_node'], registry=registry)
g.labels(act_node).set(mem_used_bytes)

pushadd_to_gateway('10.164.202.100:9091', job='temp_node_mem', registry=registry, timeout=200)
