#!/bin/sh

LOOKUP="/etc/httpd /etc/apache2 /etc/apache /etc/origin /etc/kubernetes /etc/etcd /etc/nginx /etc/postfix /etc/exim4 /etc/courrier /usr/local/etc/apache22 /etc/riak /etc/openvpn /etc/unbound /etc/nsd /etc/letsencrypt/live /etc/haproxy /etc/stunnel/ssl"
ME=$$
NOW=`expr $(date +%s%N) / 1000000`
PRG=`basename $0`
TEXTCOLLECTOR_ROOT=/var/lib/node-exporter
TMPFILE=/tmp/$PRG.$ME.$NOW

printMetric()
{
    if ! grep "^# HELP $1 $2" $TMPFILE >/dev/null 2>&1; then
	echo "# HELP $1 $2" >>$TMPFILE
	echo "# TYPE $1 $3" >>$TMPFILE
    fi
    if test "$5"; then
	echo "$1{path=\"$5\"} $4" >>$TMPFILE
    else
	echo "$1 $4" >>$TMPFILE
    fi
}

found=0

whendat()
{
    local timespan scale limit cpt itwas
    local year month week day hour

    timespan=`expr $2 - $1`
    year=31536000
    month=2592000
    week=604800
    day=86400
    hour=3600

    for scale in year month week day hour
    do
	eval limit=\$$scale
	if test 0$timespan -gt $limit; then
	    test "$itwas" && itwas="$itwas, "
	    cpt=0
	    while test "$timespan" -gt $limit
	    do
		cpt=`expr $cpt + 1`
		timespan=`expr $timespan - $limit`
	    done
	    if test "$cpt" -gt 1; then
		cpt="$cpt ${scale}s"
	    else
		cpt="$cpt $scale"
	    fi
	    itwas="$itwas$cpt"
	fi
    done

    echo $itwas ago
}

printMetric certificate_last_run "x509 Certificate Validity Last Probe Execution (unix timestamp)" counter `expr $NOW / 1000`
for lookup in $LOOKUP
do
    test -d $lookup || continue
    for cert in `find $lookup -type f -name '*.crt' -o -name '*.pem'`
    do
	if ! test -r "$cert"; then
	    body="$body; can't read `basename $lookup`"
	    continue
	elif ! grep '^-----BEGIN CERTIFICATE-----' "$cert" >/dev/null 2>&1; then
	    continue
	fi
	notafter=$(date -d "`openssl x509 -text -noout -in $cert 2>/dev/null | awk '/Not After :/{print $4\" \"$5\" \"$6\" \"$7\" \"$8}'`" +%s)
	test -z "$notafter" && continue
	found=`expr $found + 1`
	printMetric certificate_ttl "x509 Certificate Validity" gauge "$notafter" "$cert"
    done
done

printMetric certificate_found_count "x509 Certificates Checked" gauge $found
printMetric certificate_up "x509 Certificates Checked without Error" gauge 1

DONE=`expr $(date +%s%N) / 1000000`
ELAPSED=`expr $DONE - $NOW`
printMetric certificate_last_duration "x509 Certificates Last Execution Duration (in ms)" gauge $ELAPSED

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
