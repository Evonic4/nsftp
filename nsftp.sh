#!/bin/bash
export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
ver="v0.21"
fhome=/usr/share/nsftp/
cd $fhome


function init() 
{
logger "init start"

max_time_pushgateway=$(sed -n 1"p" $fhome"sett.conf" | tr -d '\r')
pushg_ip=$(sed -n 2"p" $fhome"sett.conf" | tr -d '\r')
pushg_port=$(sed -n 3"p" $fhome"sett.conf" | tr -d '\r')
namejob=$(sed -n 4"p" $fhome"sett.conf" | tr -d '\r')
pushg_start=$(sed -n 5"p" $fhome"sett.conf" | tr -d '\r')

sftp_host=$(sed -n 6"p" $fhome"sett.conf" | tr -d '\r')
sftp_port=$(sed -n 7"p" $fhome"sett.conf" | tr -d '\r')
sftp_user=$(sed -n 8"p" $fhome"sett.conf" | tr -d '\r')
sftp_pass=$(sed -n 9"p" $fhome"sett.conf" | tr -d '\r')
sftp_folder=$(sed -n 10"p" $fhome"sett.conf" | tr -d '\r')
sftp_pattern=$(sed -n 11"p" $fhome"sett.conf" | tr -d '\r')

every=$(sed -n 12"p" $fhome"sett.conf" | tr -d '\r')

err_count_sftp=0
sftp_on=1
}


function logger()
{
local date1=$(date '+ %Y-%m-%d %H:%M:%S')
echo $date1" nsftp: "$1
}


constructor_and_go ()
{
logger "constructor start"

rm -f $fhome"sftp_1.txt"
rm -f $fhome"sftp_2.txt"

cp -f $fhome"0.sh" $fhome"start_sftp.sh"

#echo "export SSHPASS="$sftp_pass >> $fhome"start_sftp.sh"

echo "sshpass -p "$sftp_pass" sftp -oStrictHostKeyChecking=no -oBatchMode=no -b - "$sftp_user"@"$sftp_host" 1>"$fhome"sftp_1.txt 2>"$fhome"sftp_2.txt << !" >> $fhome"start_sftp.sh"
! [ -z "$sftp_folder" ] &&	echo "   cd "$sftp_folder >> $fhome"start_sftp.sh"
echo "   ls -lh" >> $fhome"start_sftp.sh"
echo "   bye" >> $fhome"start_sftp.sh"
echo "!" >> $fhome"start_sftp.sh"
$fhome"setup.sh"

logger "constructor and go"
$fhome"start_sftp.sh"
}


zapushgateway ()
{
logger "zapushgateway"
logger "zapushgateway err_count_sftp="$err_count_sftp
logger "zapushgateway sftp_on="$sftp_on
logger "zapushgateway num_files_if0="$num_files_if0
logger "zapushgateway num_files_if1="$num_files_if1

echo "err_count_sftp "$err_count_sftp | curl -m $max_time_pushgateway --data-binary @- "http://"$pushg_ip":"$pushg_port"/metrics/job/"$namejob
echo "sftp_on "$sftp_on | curl -m $max_time_pushgateway --data-binary @- "http://"$pushg_ip":"$pushg_port"/metrics/job/"$namejob
echo "num_files_if "$num_files_if0 | curl -m $max_time_pushgateway --data-binary @- "http://"$pushg_ip":"$pushg_port"/metrics/job/"$namejob"/pattern/0"
echo "num_files_if "$num_files_if1 | curl -m $max_time_pushgateway --data-binary @- "http://"$pushg_ip":"$pushg_port"/metrics/job/"$namejob"/pattern/1"
}



razmer_v_B ()
{
rm -f $fhome"sftp_1_r1.txt"

str_col2=$(grep -c "" $fhome"sftp_1_r.txt")
logger "razmer_v_B start str_col2="$str_col2

if [ "$str_col2" -gt "0" ]; then 
for (( i2=1;i2<=$str_col2;i2++)); do
	test=$(sed -n $i2"p" $fhome"sftp_1_r.txt" | tr -d '\r')
	if [ "$(echo $test | grep -c "G" )" -gt "0" ]; then
		test1=$(echo $test | sed 's/G//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
		test1=$(echo "$test1*1024*1024*1024" | bc)
	fi
	if [ "$(echo $test | grep -c "M" )" -gt "0" ]; then
		test1=$(echo $test | sed 's/M//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
		test1=$(echo "$test1*1024*1024" | bc)
	fi
	if [ "$(echo $test | grep -c "K" )" -gt "0" ]; then
		test1=$(echo $test | sed 's/M//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
		test1=$(echo "$test1*1024" | bc)
	fi
	if [ "$(echo $test | grep -c "B" )" -gt "0" ]; then
		test1=$(echo $test | sed 's/B//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
	fi
	echo $test1 >> $fhome"sftp_1_r1.txt"
	logger "razmer_v_B "$test" -> "$test1
done
else
	logger "razmer_v_B str_col2=0"
fi
}




watcher ()
{
logger "watcher start"
constructor_and_go;
sco1=$(wc -m $fhome"sftp_1.txt" | awk '{ print $1 }')
sco2=$(wc -m $fhome"sftp_2.txt" | awk '{ print $1 }')
logger "watcher sco1="$sco1" sco2="$sco2
sftp_on=0

if [ "$sco2" -gt "1" ] && [ "$(grep -c 'Permanently added' $fhome"sftp_2.txt")" -eq "0" ]; then		#error
	err_count_sftp=$((err_count_sftp+1))
	logger "watcher err_count_sftp="$err_count_sftp
fi
[ "$sco1" -gt "1" ] && sftp_on=1
if [ "$sco1" -gt "1" ] && [ "$(grep -c '' $fhome"sftp_1.txt")" -gt "3" ]; then
	grep -E "$sftp_pattern" $fhome"sftp_1.txt" > $fhome"sftp_11.txt"
	num_files_if0=$(grep -c "" $fhome"sftp_11.txt")
	logger "watcher num_files_if0="$num_files_if0
	
	#имена
	#cat $fhome"sftp_11.txt" | awk '{ print $9 }' > $fhome"sftp_1_name.txt"
	#размеры
	cat $fhome"sftp_11.txt" | awk '{ print $5 }' > $fhome"sftp_1_r.txt"
	
	razmer_v_B;
	
	grep '' $fhome"sftp_1_r1.txt" | awk '$1>1024 {print}' > $fhome"sftp_1_r2.txt"
	num_files_if1=$(grep -c "" $fhome"sftp_1_r2.txt")
	logger "watcher num_files_if1="$num_files_if1
fi
if [ "$sco1" -eq "0" ] && [ "$sco2" -eq "0" ]; then
	logger "watcher sco1=sco2=0 ERROR"
	sftp_on=-1
fi
logger "watcher sftp_on="$sftp_on
}


pushgateway_start ()	#9044-9050
{
logger "pushgateway_start pushg_port="$pushg_port
cp -f $fhome"0.sh" $fhome"start_pg.sh"
echo "su pushgateway -c '/usr/local/bin/pushgateway --web.listen-address=0.0.0.0:${pushg_port}' -s /bin/bash 1>/dev/null 2>/dev/null &" >> $fhome"start_pg.sh"
chmod +rx $fhome"start_pg.sh"
$fhome"start_pg.sh" &
}



#START
logger " "
cp -f $fhome"settings.conf" $fhome"sett.conf"

init;
logger "start nsftp "$ver
[ "$pushg_start" -eq "1" ] && pushgateway_start;
sleep 5

while true
do
logger "sleep "$every" m"
sleep 5
sleep $every"m"
watcher;
zapushgateway;
done

