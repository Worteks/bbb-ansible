#!/bin/sh

ME=$$
NOW=`expr $(date +%s%N) / 1000000`
PRG=`basename $0`
TEXTCOLLECTOR_ROOT=/var/lib/node-exporter
TMPFILE=/tmp/$PRG.$ME.$NOW
TMPFILE2=/tmp/$PRG.$ME.prom.$NOW

printMetric()
{
    echo "# HELP $1 $2"
    echo "# TYPE $1 $3"
    echo "$1 $4"
}

BBBSVC="nginx freeswitch redis-server bbb-apps-akka bbb-transcode-akka
	bbb-fsesl-akka red5 mongod bbb-html5 bbb-webrtc-sfu etherpad
	kurento-media-server bbb-web"

printMetric bbb_services_last_run "BigBlueButton Services Last Probe Execution (unix timestamp)" counter `expr $NOW / 1000` >$TMPFILE2

if bbb-conf --status >$TMPFILE 2>/dev/null; then
    for svc in $BBBSVC
    do
	metric=$(echo $svc | sed 's|[^a-zA-Z0-9]|_|g')
	is_up=0
	if grep -E "^$svc.*active" $TMPFILE >/dev/null; then
	    is_up=1
	fi
	printMetric bbb_services_${metric}_up "BigBlueButton $svc Service Status" gauge $is_up >>$TMPFILE2
    done
else
    for svc in $BBBSVC
    do
	metric=$(echo $svc | sed 's|[^a-zA-Z0-9]|_|g')
	printMetric bbb_services_${metric}_up "BigBlueButton $svc Service Status" gauge 0 >>$TMPFILE2
    done
fi

DONE=`expr $(date +%s%N) / 1000000`
ELAPSED=`expr $DONE - $NOW`
printMetric bbb_services_last_duration "BigBlueButton Services Last Execution Duration (in ms)" gauge $ELAPSED >>$TMPFILE2

if test -s $TMPFILE2; then
    if test -d $TEXTCOLLECTOR_ROOT; then
	mv $TMPFILE2 $TEXTCOLLECTOR_ROOT/$PRG.prom
    else
	cat $TMPFILE2
	rm -f $TMPFILE2
    fi
else
    rm -f $TMPFILE2
fi
rm -f $TMPFILE

exit 0
