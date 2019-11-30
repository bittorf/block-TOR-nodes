#!/bin/sh

ACTION="$1"	# start|stop|update

# https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=1.1.1.1
URL='https://www.dan.me.uk/torlist/?exit'

FILE="/tmp/list.txt"
IPT4='iptables --wait'
IPT6='ip6tables --wait'
WGET_OPTS='--no-check-certificate --quiet'

usage_show()
{
	echo "Usage: $0 <start|stop|update>"
	false
}

list_download()
{
	local url="$1"

	# shellcheck disable=SC2086
	wget $WGET_OPTS --output-document=- "$url"
}

is_ipv4()
{
	local word="$1"

	case "$word" in
		[0-9].*|[0-9][0-9].*|[0-9][0-9][0-9].*)
			# e.g. 102.130.112.81
			# e.g. 102.*
			true
		;;
		*)
			false
		;;
	esac
}

is_ipv6()
{
	local word="$1"
	local hex='[0-9a-f]'

	case "$word" in
		${hex}:*|${hex}${hex}:*|${hex}${hex}${hex}:*|${hex}${hex}${hex}${hex}:*)
			# e.g. 2001:41d0:0052:0d00:0000:0000:0000:0025
			# e.g. 2001:*
			true
		;;
		*)
			false
		;;
	esac
}

netfilter_chain_remove()
{
	local name="$1"
	local force="$2"

	{
		[ "$force" ] && $IPT4 -D INPUT -j "$name"
		$IPT4 --flush        "$name"
		$IPT4 --delete-chain "$name"

		[ "$force" ] && $IPT6 -D INPUT -j "$name"
		$IPT6 --flush        "$name"
		$IPT6 --delete-chain "$name"

	} 2>/dev/null
}

netfilter_atomic_replace()
{
	local name="$1"
	
	$IPT4 --rename-chain "$name"           "$name-old" 2>/dev/null
	$IPT4 --rename-chain "$name-temporary" "$name"

	$IPT6 --rename-chain "$name"           "$name-old" 2>/dev/null
	$IPT6 --rename-chain "$name-temporary" "$name"

	netfilter_chain_remove "$name-old" force
}

netfilter_apply()
{
	local file="$1"
	local ip

	$IPT4 --new 'tor-temporary' || return 1
	$IPT6 --new 'tor-temporary' || return 1

	while read -r ip; do {
		is_ipv4 "$ip" && $IPT4 -A tor-temporary -s "$ip/32" -j REJECT && continue
		is_ipv6 "$ip" && $IPT6 -A tor-temporary -s "$ip/64" -j REJECT
	} done <"$file"

	netfilter_atomic_replace 'tor'
}

download_and_apply()
{
	list_download "$URL" >"$FILE" && {
		netfilter_apply "$FILE" && {
			$IPT4 -I INPUT -j tor 2>/dev/null
			$IPT6 -I INPUT -j tor 2>/dev/null
		}
	}
}

case "$ACTION" in
	start|update)
		download_and_apply
	;;
	stop)
		netfilter_chain_remove 'tor' force
		netfilter_chain_remove 'tor-old' force
		netfilter_chain_remove 'tor-temporary' force
	;;
	*)
		usage_show
	;;
esac
