#!/bin/bash
# from: https://gitlab.rlp.net/zdvsysunix-public/bbb/bbb-helper/-/blob/main/monitoring/redis-scalelite

REDIS_HOST=127.0.0.1
REPAIR=false

while test "$1"
do
    case "$1" in
	-h|--host)
	    REDIS_HOST=$2
	    shift
	    ;;
	-r|--repair)
	    REPAIR=true
	    ;;
	*)
	    echo "WARNING: discarding unknown option $1" >&2
	    ;;
    esac
    shift
done

rediswrite()
{
    redis-cli -h $REDIS_HOST $@
}

status=0
statustxt=

SERVERS1=$(diff -w <(redis-cli keys scalelite:server:* | cut -d: -f3|sort) <(redis-cli keys scalelite:*|egrep -v "server|meeting|health" |cut -d: -f2|sort) | egrep "[<>]" | tr '\n' ' ')
SERVERS=$(diff -w <(redis-cli keys scalelite:server:* | cut -d: -f3|sort) <(redis-cli smembers scalelite:servers |sort) | egrep "(<|>)" | tr '\n' ' ')
MEETINGS=$(diff -w <(redis-cli keys scalelite:meeting:* | cut -d: -f3|sort) <(redis-cli smembers scalelite:meetings |sort) | egrep "(<|>)" | tr '\n' ' ')
SERVENA=$(diff -w <(redis-cli smembers scalelite:server_enabled | cut -d: -f3|sort) <(redis-cli zrange scalelite:server_load 0 -1 |sort) | egrep "[<>]" | tr '\n' ' ')
MEETSERV=$(for meeting in $(redis-cli keys scalelite:meeting:* | cut -d\" -f3); do redis-cli smembers scalelite:servers | grep -q "$(redis-cli hget $meeting server_id)" || echo -n $meeting | cut -d: -f3 | tr '\n' ' ' ; done)

if test -n "$SERVERS1"; then
    redisscalelite="scalelite:server:* <-> scalelite:*:$SERVERS1 "
    statustxt="servers differ: "
    status=1
    if $REPAIR; then
	for server in $(echo $SERVERS1 | tr '>' ' ')
	do
	    echo $server
	    rediswrite del scalelite:$server
	done
    fi
fi

if test -n "$SERVERS"; then
    redisscalelite="$redisscalelite; scalelite:server:* <-> scalelite:servers:$SERVERS "
    statustxt="servers differ: "
    status=1
    if $REPAIR; then
	rediswrite srem scalelite:servers $(echo $SERVERS | tr '>' ' ')
    fi
fi

if test -n "$MEETINGS"; then
    redisscalelite="$redisscalelite; scalelite:meeting:* <-> scalelite:meetings:$MEETINGS "
    statustxt="$statustxt meetings differ: "
    if $REPAIR; then
	rediswrite srem scalelite:meetings $(echo $MEETINGS | tr '>' ' ')
    fi
    status=1
fi

if test -n "$SERVENA"; then
    redisscalelite="$redisscalelite; scalelite:server_enabled <-> scalelite:server_load:$SERVENA "
    statustxt="$statustxt enabled servers differ: "
    status=2
#    if $REPAIR; then
#	rediswrite srem scalelite:server_enabled $(echo $SERVENA | tr '<' ' ')
#    fi
fi

if test -n "$MEETSERV"; then
    redisscalelite="$redisscalelite; scalelite:server missing for meeting:$MEETSERV "
    statustxt="$statustxt server for meeting missing: "
    status=2
    if $REPAIR; then
	for meeting in $MEETSERV
	do
	    echo $meeting
	    rediswrite del scalelite:meeting:$meeting
	done
    fi
fi

echo "$status redis-scalelite - $statustxt${redisscalelite:--}"
exit $status
