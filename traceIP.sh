#!/bin/bash

source /etc/profile

date=$(date +"%Y-%m-%d %H:%M:%S")
workdir=/root/iptest
localip=`ifconfig | grep 'inet addr' | egrep -v '127.0.0.1|192.168|172.16' | awk '{print $2}' | awk -F \: '{print $2}'`
ip=$workdir/$1/ip
testip=$workdir/$1/testip
testdata=$workdir/$1/ipdata/ipdata
testerror=$workdir/$1/ipdata/errorip
testaccessful=$workdir/$1/ipdata/accessfulip
influxdb_write_url="http://60.xx.xx.xx:8086/write?db=" #influxdb 地址
influxdb_name="network" #influxdb 数据库
 

if [ -f $workdir ]
then
        rm -f $workdir ; mkdir -p $workdir/$1/ipdata ; echo "$workdir/$1/ipdata"
else
        if [ -d $workdir/$1/ipdata ]
        then
                echo "$workdir/$1/ipdata"
        else
                mkdir -p $workdir/$1/ipdata;echo "$workdir/$1/ipdata"
        fi
fi

touch $ip
curl -s "http://yw.xx.com:8100/get_ip.php?type=$1" > $ip#获取IP列表
cat $ip | awk -F \-  '{print $1}' > $workdir/$1/testip 

cutdata_accessful(){
for i in `cat $testaccessful | grep -v ICMPTimeExceededfrom | awk '{print $1}'`
do
	isp=`cat $ip | grep $i | awk -F '-' '{print $4}'`
	region=`cat $ip | grep $i | awk -F '-' '{print $2}'`
	city=`cat $ip | grep $i | awk -F '-' '{print $3}'`
	xmt=`cat $testaccessful | grep -w $i | awk '{print $2}' | awk -F \= '{print $2}' | awk -F \- '{print $1}'`
	rcv=`cat $testaccessful | grep -w $i | awk '{print $2}' | awk -F \= '{print $2}' | awk -F \- '{print $2}'`
	loss=`cat $testaccessful | grep -w $i | awk '{print $2}' | awk -F \= '{print $2}' | awk -F \- '{print $3}' | tr -d '%'`
	min=`cat $testaccessful | grep -w $i | awk '{print $3}' | awk -F \= '{print $2}' | awk -F \- '{print $1}'`
	avg=`cat $testaccessful | grep -w $i | awk '{print $3}' | awk -F \= '{print $2}' | awk -F \- '{print $2}'`
	max=`cat $testaccessful | grep -w $i | awk '{print $3}' | awk -F \= '{print $2}' | awk -F \- '{print $3}'`
	curl -s -XPOST "$influxdb_write_url$influxdb_name" --data-binary "$influxdb_name,Host_IP=$localip,Target=$i,isp=$isp,region=$region,city=$city xmt=$xmt,rcv=$rcv,loss=$loss,avg=$avg,max=$max,min=$min"
done
}

cutdata_error(){
for i in `cat $testerror | grep -v ICMPTimeExceededfrom | awk '{print $1}'`
do
        isp=`cat $ip | grep $i | awk -F '-' '{print $4}'`
        region=`cat $ip | grep $i | awk -F '-' '{print $2}'`
        city=`cat $ip | grep $i | awk -F '-' '{print $3}'`
        xmt=`cat $testerror | grep -w $i | awk '{print $2}' | awk -F \= '{print $2}' | awk -F \- '{print $1}'`
        rcv=`cat $testerror | grep -w $i | awk '{print $2}' | awk -F \= '{print $2}' | awk -F \- '{print $2}'`
        loss=`cat $testerror | grep -w $i | awk '{print $2}' | awk -F \= '{print $2}' | awk -F \- '{print $3}' | tr -d '%'`
        min=`cat $testerror | grep -w $i | awk '{print $3}' | awk -F \= '{print $2}' | awk -F \- '{print $1}'`
        avg=`cat $testerror | grep -w $i | awk '{print $3}' | awk -F \= '{print $2}' | awk -F \- '{print $2}'`
        max=`cat $testerror | grep -w $i | awk '{print $3}' | awk -F \= '{print $2}' | awk -F \- '{print $3}'`
	curl -s -XPOST "$influxdb_write_url$influxdb_name" --data-binary "$influxdb_name,Host_IP=$localip,Target=$i,isp=$isp,region=$region,city=$city xmt=$xmt,rcv=$rcv,loss=$loss,avg=0,max=0,min=0"
done
}

startfping(){
	/usr/sbin/fping -q -c 20 -f $testip > $testdata 2>&1
	cat $testdata | grep 'min/avg/max' | tr -d ' ' | tr '/' '-' | tr ',' ' ' | tr ':' ' ' > $testaccessful
	cat $testdata | grep -v 'min/avg/max' | tr -d ' ' | tr '/' '-' | tr ',' ' ' | tr ':' ' ' > $testerror
	cutdata_accessful
	cutdata_error
}

startfping
