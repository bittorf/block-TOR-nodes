# setup

use hourly cronjob as user 'root' for regular updates:
```
6 * * * * /usr/local/bin/tornodes_block.sh update
```

# description

IP-lists are fetched from 'https://www.dan.me.uk/torlist/?exit'.

iptables replacement of new rules works nearly atomic.
