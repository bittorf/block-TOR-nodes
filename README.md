# setup

use hourly cronjob as user 'root' for regular updates:
```
6 * * * * /usr/local/bin/tornodes_block.sh update
```

# description

IP-lists are fetched from
```
'https://www.dan.me.uk/torlist/?exit' and
'https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=1.1.1.1'.
```

iptables replacement of new rules works nearly atomic.


# iptables rule layout and logic

```
# send all incoming traffic to chain 'tor':
Chain INPUT (policy ACCEPT 11031 packets, 6043475 bytes)
    pkts      bytes target     prot opt in     out     source               destination
   11031  6043475 tor        all  --  *      *       0.0.0.0/0            0.0.0.0/0


# everything that matches gets REJECTED here:
Chain tor (1 references)
    pkts      bytes target     prot opt in     out     source               destination
       0        0 REJECT     all  --  *      *       103.15.28.215        0.0.0.0/0      reject-with icmp-port-unreachable
       5     4108 REJECT     all  --  *      *       103.208.220.122      0.0.0.0/0      reject-with icmp-port-unreachable
       0        0 REJECT     all  --  *      *       103.208.220.226      0.0.0.0/0      reject-with icmp-port-unreachable

[...]

```
