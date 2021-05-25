#!/bin/sh

ME=$$
NOW=`expr $(date +%s%N) / 1000000`
PRG=`basename $0`
TEXTCOLLECTOR_ROOT=/var/lib/node-exporter
TMPFILE=/tmp/$PRG.$ME.$NOW
TMPOUT=/tmp/$PRG.out.$ME.$NOW

printMetric()
{
    if ! grep "^# HELP $1 $2" $TMPFILE >/dev/null 2>&1; then
	echo "# HELP $1 $2" >>$TMPFILE
	echo "# TYPE $1 $3" >>$TMPFILE
    fi
    if test "$6"; then
	echo "$1{jail=\"$6\",counter=\"$5\"} $4" >>$TMPFILE
    elif test "$5"; then
	echo "$1{counter=\"$5\"} $4" >>$TMPFILE
    else
	echo "$1 $4" >>$TMPFILE
    fi
}

printMetric fail2ban_last_run "Fail2ban Last Probe Execution (unix timestamp)" counter `expr $NOW / 1000`

hasjails=0
if ! fail2ban-client status >/dev/null 2>&1; then
    UP=0
else
    UP=1
    JAILS=`fail2ban-client status | awk '/Jail list/' | sed -e 's|^.*Jail list:[ \t]*||g' -e 's|,||g'`
    for jail in $JAILS
    do
	fail2ban-client status $jail >$TMPOUT
	curfail=`awk '/Currently failed:/{print $NF}' $TMPOUT`
	totfail=`awk '/Total failed:/{print $NF}' $TMPOUT`
	curban=`awk '/Currently banned:/{print $NF}' $TMPOUT`
	totban=`awk '/Total banned:/{print $NF}' $TMPOUT`
	printMetric fail2ban_filter_stats "Fail2ban Filter Current Stats" gauge "$curfail" failed $jail
	printMetric fail2ban_filter_stats "Fail2ban Filter Current Stats" gauge "$curban" banned $jail
	printMetric fail2ban_totals "Fail2ban Filter Total Stats" gauge "$totfail" failed $jail
	printMetric fail2ban_totals "Fail2ban Filter Total Stats" gauge "$totban" banned $jail
	hasjails=`expr $hasjails + 1`
    done
fi

printMetric fail2ban_up "Fail2ban process Running" gauge $UP
printMetric fail2ban_jails "Fail2ban Active Jails Count" gauge $hasjails

DONE=`expr $(date +%s%N) / 1000000`
ELAPSED=`expr $DONE - $NOW`
printMetric fail2ban_last_duration "Fail2ban Stast Collection Duration (in ms)" gauge $ELAPSED

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
rm -f $TMPOUT

exit 0
