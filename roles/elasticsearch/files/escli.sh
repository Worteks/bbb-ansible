#!/bin/sh

CLOSE_AFTER=30
ESROOT=http://127.0.0.1:9200
PRG=`basename $0`
SET_REPLICAS=1

help()
{
    cat <<EOF
$PRG: usage
    $PRG close-index [indexname] - Closes index
    $PRG close-older [$CLOSE_AFTER] - Closes indexes older than 30d
    $PRG delete-index [indexname] - Deletes index
    $PRG get-status - Gets Cluster Status
    $PRG list-index - Lists indexes
    $PRG list-shards - Lists shards
    $PRG open-index [indexname] - Opens index
    $PRG set-replicas [indexname] [$SET_REPLICAS] - Sets given index replicas count
    $PRG set-replicas [$SET_REPLICAS] - Sets all indexes replicas count
    $PRG zero-replicas - Sets unassigned shards index replicas count to 0 (standalone ES)
EOF
}

close_index()
{
    local idx

    idx=${1:-changeme}
    curl -XPOST "$ESROOT/$idx/_close" 2>/dev/null
}

delete_index()
{
    local idx

    idx=${1:-changeme}
    curl -XDELETE "$ESROOT/$idx" 2>/dev/null
}

get_cluster_status()
{
    local stt
    stt=$(curl "$ESROOT/_cluster/health" 2>/dev/null | sed 's|^.*"status":"\([a-z]*\)".*|\1|')
    if test -z "$stt"; then
	echo unknown
    else
	echo $stt
    fi
}

list_indexes()
{
    curl "$ESROOT/_cat/indices" 2>/dev/null
}

list_shards()
{
    curl "$ESROOT/_cat/shards" 2>/dev/null
}

open_index()
{
    local idx

    idx=${1:-changeme}
    curl -XPOST "$ESROOT/$idx/_open" 2>/dev/null
}

set_index_replicas()
{
    local idx replicas

    idx=${1:-changeme}
    replicas=${2:-0}
    curl -H 'Content-Type: application/json' \
	-XPUT "$ESROOT/$idx/_settings" \
	-d "{ \"index\": {\"number_of_replicas\": $replicas } }" \
	2>/dev/null
}

###

close_older_than()
{
    local older_stamp today_stamp after

    after=${1:-30}
    older_stamp=`expr $after '*' 86400`
    today_stamp=`date +%s`
    list_indexes | awk '/logstash/{print $3}' | while read idx
	do
	    datestring=`echo $idx | sed 's|logstash-\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)|\1/\2/\3|'`
	    daystamp=`date -d "$datestring" +%s`
	    #echo "idx-stamp:$daystamp + limit:$older_stamp vs. today:$today_stamp"
	    if test `expr $daystamp + $older_stamp` -le $today_stamp; then
		echo "NOTICE: closing index $idx"
		close_index $idx
		echo
	    fi
	done
}

set_indexes_replicas()
{
    local rpl

    rpl=${2:0}
    list_indexes | awk '/logstash/{print $3}' | while read idx
	do
	    set_index_replicas $idx $rpl
	done
}

zero_replicas()
{
    list_shards | awk '/UNAS/{print $1}' | while read idx;
        do
	    set_index_replicas $idx 0
	    echo
        done
}

case "$1" in
    close-older|close-after|co)
	test "$2" && CLOSE_AFTER=$2
	close_older_than $CLOSE_AFTER
	;;
    close-index|ci)
	index=${2:-changeme}
	close_index $index
	echo
	;;
    delete-index|di)
	index=${2:-changeme}
	delete_index $index
	echo
	;;
    get-status|status|gs)
	get_cluster_status
	echo
	;;
    list-index|list-indexes|li)
	list_indexes | sort
	;;
    list-shard|list-shards|ls)
	list_shards | sort
	;;
    open-index|oi)
	index=${2:-changeme}
	open_index $index
	echo
	;;
    set-replica|set-replicas|sc)
	if test "$3"; then
	    index=$2
	    replicas=$3
	elif test "$2" -ge 0; then
	    replicas=$2
	else
	    index=$2
	fi
	test -z "$replicas" && replicas=$SET_REPLICAS
	if test -z "$index"; then
	    set_indexes_replicas $replicas
	else
	    set_index_replicas $index $replicas
	fi
	echo
	;;
    zero-replica|zero-replicas|zc)
	zero_replicas
	;;
    *)
	help
	if test "$1" = -h -o "$1" = --help -o "$1" = help; then
	    exit 0
	fi
	exit 1
	;;
esac

exit 0
