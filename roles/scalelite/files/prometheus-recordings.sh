#!/bin/sh

ME=$$
NOW=`expr $(date +%s%N) / 1000000`
PRG=`basename $0`
RECORDINGS_ROOT=/var/scalelite-recordings
TEXTCOLLECTOR_ROOT=/var/lib/node-exporter
TMPFILE=/tmp/$PRG.$ME.$NOW

printMetric()
{
    echo "# HELP $1 $2"
    echo "# TYPE $1 $3"
    echo "$1 $4"
}

SPOOL_COUNT=$(find $RECORDINGS_ROOT/spool/  -maxdepth 1 -type d | grep -v "^$RECORDINGS_ROOT/spool/$" | awk 'END{print NR}')
PUBLISHED_COUNT=$(find $RECORDINGS_ROOT/published/  -maxdepth 1 -type d | grep -v "^$RECORDINGS_ROOT/published/$" | awk 'END{print NR}')
UP=0
if test -d $RECORDINGS_ROOT/spool; then
    if docker exec scalelite-recording-importer echo OK; then
	UP=1
    fi >/dev/null 2>&1
fi

(
    printMetric scalelite_recordings_last_run "Scalelite Recordings Last Probe Execution (unix timestamp)" counter `expr $NOW / 1000`
    printMetric scalelite_recordings_spool_count "Scalelite Recordings in Spool" gauge $SPOOL_COUNT
    printMetric scalelite_recordings_published_count "Scalelite Recordings Published" gauge $PUBLISHED_COUNT
    printMetric scalelite_recordings_up "Scalelite Recordings Importer is Running" gauge $UP

    DONE=`expr $(date +%s%N) / 1000000`
    ELAPSED=`expr $DONE - $NOW`
    printMetric scalelite_recordings_last_duration "Scalelite Recordings Last Execution Duration (in ms)" gauge $ELAPSED
) >$TMPFILE

if test -s $TMPFILE; then
    if test -d $TEXTCOLLECTOR_ROOT; then
	mv $TMPFILE $TEXTCOLLECTOR_ROOT/$PRG.prom
    else
	cat $TMPFILE
	rm -f $TMPFILE
    fi
else
    rm -f $TMPFILE
fi

exit 0
