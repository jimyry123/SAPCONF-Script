#! /usr/bin/bash

SEMMSL_MIN=1250
SEMMNS_MIN=256000
SEMOPM_MIN=100
SEMMNI_MIN=8192

MAX_MAP_COUNT_MIN=2000000

MAIN_MEMORY_TOTAL=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')
SWAP_SPACE_TOTAL=$(cat /proc/meminfo | grep SwapTotal | awk '{ print $2 }')
VIRT_MEMORY_TOTAL=$(( ${MAIN_MEMORY_TOTAL} + ${SWAP_SPACE_TOTAL} ))

VIRT_MEMORY_TOTAL=$(( ( ${VIRT_MEMORY_TOTAL} + 1048576 ) / 1048576 ))

# Required size of TMPFS: (RAM + SWAP) * 0,75 (SAP Note 941735)
TMPFS_SIZE_REQ=$(( $VIRT_MEMORY_TOTAL * 75 / 100 ))

# kernel.shmall is in 4 KB pages; minimum 20 GB (SAP Note 941735)
SHMALL_REQ=$(( $VIRT_MEMORY_TOTAL * 1024 * 1024 / 4 ))
# kernel.shmmax is in Bytes; minimum 20 GB (SAP Note 941735)
SHMMAX_REQ=$(( $VIRT_MEMORY_TOTAL * 1024 * 1024 * 1024 ))
#TMPFS_SIZE_REQ=48
#SHMALL_REQ=16777216
#SHMMAX_REQ=68719476736

SHMMAX=$(cat /proc/sys/kernel/shmmax)

SEMMSL=$(cat /proc/sys/kernel/sem | awk '{print $1}')
SEMMNS=$(cat /proc/sys/kernel/sem | awk '{print $2}')
SEMOPM=$(cat /proc/sys/kernel/sem | awk '{print $3}')
SEMMNI=$(cat /proc/sys/kernel/sem | awk '{print $4}')
h=$(hostname)
hs=$(hostname -s)
hl=$(hostname -f)
dn=$(dnsdomainname)
fix_localhost=0
num_ip=$( grep "^${ip}" /etc/hosts | wc -l)

SHMALL=$(cat /proc/sys/kernel/shmall)
MAX_MAP_COUNT=$(cat /proc/sys/vm/max_map_count)
TMPFS_SIZE=`df -k /dev/shm | tail -n 1 | awk '{print $2}'`
TMPFS_SIZE=$(( ( $TMPFS_SIZE + 1048576 ) / 1048576))


#TMPFS_SIZE_FINAL=$(if [ $TMPFS_SIZE -ge $TMPFS_SIZE_REQ ]; then echo "passed"; else echo "failed";fi)
#SHMALL_FINAL=$(if [ $SHMALL -ge $SHMALL_REQ ]; then echo "passed"; else echo "failed"; fi)
#SHMMAX_FINAL=$(if [ $SHMMAX -ge $SHMMAX_REQ ]; then echo "passed"; else echo "failed"; fi) 
#SEMMSL_FINAL=$(if [ $SEMMSL -ge $SEMMSL_MIN ]; then echo "passed"; else echo "failed"; fi)
#SEMMNS_FINAL=$(if [ $SEMMNS -ge $SEMMNS_MIN ]; then echo "passed"; else echo "failed"; fi)
#SEMOPM_FINAL=$(if [ $SEMOPM -ge $SEMOPM_MIN ]; then echo "passed"; else echo "failed"; fi)
#SEMMNI_FINAL=$(if [ $SEMMNI -ge $SEMMNI_MIN ]; then echo "passed"; else echo "failed"; fi)
#MAX_FINAL=$(if [ $MAX_MAP_COUNT -ge $MAX_MAP_COUNT_MIN ]; then echo "passed"; else echo "failed"; fi)
REQUIRED_MAJOR_VERSION=2
REQUIRED_MINOR_VERSION=17
REQUIRED_BUILD_VERSION=73
REQUIRED_BUILD_MINOR_VERSION=0
ARCHITECTURE=$(rpm -q glibc | rev | cut -d'.' -f1 | rev)
MAJOR_VERSION=$(rpm -q glibc | cut -d'-' -f2 | cut -d'.' -f1)
MINOR_VERSION=$(rpm -q glibc | cut -d'-' -f2 | cut -d'.' -f2)
BUILD_VERSION=$(rpm -q glibc | cut -d'-' -f3 | cut -d'.' -f1)
BUILD_MINOR_VERSION=$(rpm -q glibc | rev | cut -d'.' -f2- | rev | cut -s -d'_' -f2 | cut -d'.' -f2)

glibc_major_verson=$(if [[ "MAJOR_VERSION" == "REQUIRED_MAJOR_VERSION" ]]; then echo "100"; else echo "0"; fi)
glibc_minor_version=$(if [[ "MINOR_VESION" == "REQUIRED_MINOR_VERSION" ]]; then echo "100"; else echo "0"; fi)
glibc_build_version=$(if [[ "BUILD_VERSION" == "REQUIRED_BUILD_VERSION" ]]; then echo "100"; else echo "0"; fi)
glibc_minor_version=$(if [[ "BUILD_MINOR_VERSION" == "REQUIRED_BUILD_MINOR_VERSION" ]]; then echo "100"; else echo "0"; fi)
No_files=$(ulimit -n)
Max_proc=$(ulimit -u)

s=$(env)
sname='SAPSYSTEMNAME='
s="${s##*$sname}"
ts="./${s:0:3}"
com=$(ls -ld /stage/SAPUSERS/SAP/sapusers/SAPUSERS_PERFTEST/SAPCONF/*/)
coms=$(find -maxdepth 1 -type d)

for v in $coms;do
if [[ $v == $ts ]];
then path="$v/${h}"
fi
done

while IFS=, read -r col1 col2 col3
do
    if [[ "./$col1/$col2" == $path ]];
        then virtual="$col3"
fi
done < sapconf_list.csv
sed -i 's/^M$//' sapconf.csv

substring=${virtual:0:3}

while IFS=, read -r col1 col2 col3 col4 col5; 
do 
     if [[ "$col1" == $ts && "$col2" =~ "PAS" && "$col3" =~ "MAX_MAP_COUNT" ]];
        then Max_count_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "pas" && "$col3" =~ "MAX_MAP_COUNT" ]];
        then Max_count_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "db" && "$col3" =~ "MAX_MAP_COUNT" ]];
        then Max_count_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "DB" && "$col3" =~ "MAX_MAP_COUNT" ]];
        then Max_count_req="$col4"
fi 
done <sapconf.csv

while IFS=, read -r col1 col2 col3 col4 col5;
do
     if [[ "$col1" == $ts && "$col2" =~ "PAS" && "$col3" =~ "Max proc" ]];
        then Max_proc_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "pas" && "$col3" =~ "Max proc" ]];
        then Max_proc_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "db" && "$col3" =~ "Max proc" ]];
        then Max_proc_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "DB" && "$col3" =~ "Max proc" ]];
        then Max_proc_req="$col4"
fi
done <sapconf.csv

while IFS=, read -r col1 col2 col3 col4 col5;
do
     if [[ "$col1" == $ts && "$col2" =~ "PAS" && "$col3" =~ "Number of files" ]];
        then No_files_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "pas" && "$col3" =~ "Number of files" ]];
        then No_files_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "db" && "$col3" =~ "Number of files" ]];
        then No_files_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "DB" && "$col3" =~ "Number of files" ]];
        then No_files_req="$col4"
fi
done <sapconf.csv

while IFS=, read -r col1 col2 col3 col4 col5;
do
     if [[ "$col1" == $ts && "$col2" =~ "PAS" && "$col3" =~ "SEMMNI" ]];
        then Semmni_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "pas" && "$col3" =~ "SEMMNI" ]];
        then Semmni_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "db" && "$col3" =~ "SEMMNI" ]];
        then Semmni_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "DB" && "$col3" =~ "SEMMNI" ]];
        then Semmni_req="$col4"
fi
done <sapconf.csv


while IFS=, read -r col1 col2 col3 col4 col5;
do
     if [[ "$col1" == $ts && "$col2" =~ "PAS" && "$col3" =~ "SEMMNS" ]];
        then Semmns_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "pas" && "$col3" =~ "SEMMNS" ]];
        then Semmns_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "db" && "$col3" =~ "SEMMNS" ]];
        then Semmns_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "DB" && "$col3" =~ "SEMMNS" ]];
        then Semmns_req="$col4"
fi
done <sapconf.csv


while IFS=, read -r col1 col2 col3 col4 col5;
do
     if [[ "$col1" == $ts && "$col2" =~ "PAS" && "$col3" =~ "SEMMSL" ]];
        then Semmsl_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "pas" && "$col3" =~ "SEMMSL" ]];
        then Semmsl_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "db" && "$col3" =~ "SEMMSL" ]];
        then Semmsl_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "DB" && "$col3" =~ "SEMMSL" ]];
        then Semmsl_req="$col4"
fi
done <sapconf.csv


while IFS=, read -r col1 col2 col3 col4 col5;
do
     if [[ "$col1" == $ts && "$col2" =~ "PAS" && "$col3" =~ "SEMOPM" ]];
        then Semopm_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "pas" && "$col3" =~ "SEMOPM" ]];
        then Semopm_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "db" && "$col3" =~ "SEMOPM" ]];
        then Semopm_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "DB" && "$col3" =~ "SEMOPM" ]];
        then Semopm_req="$col4"
fi
done <sapconf.csv


while IFS=, read -r col1 col2 col3 col4 col5;
do
     if [[ "$col1" == $ts && "$col2" =~ "PAS" && "$col3" =~ "SHMALL" ]];
        then Shmall_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "pas" && "$col3" =~ "SHMALL" ]];
	then Shmall_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "DB" && "$col3" =~ "SHMALL" ]];
	then Shmall_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "db" && "$col3" =~ "SHMALL" ]];
	then Shmall_req="$col4"
fi
done <sapconf.csv


while IFS=, read -r col1 col2 col3 col4 col5;
do
     if [[ "$col1" == $ts && "$col2" =~ "PAS" && "$col3" =~ "SHMMAX" ]];
        then Shmmax_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "pas" && "$col3" =~ "SHMMAX" ]];
        then Shmmax_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "db" && "$col3" =~ "SHMMAX" ]];
        then Shmmax_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "DB" && "$col3" =~ "SHMMAX" ]];
        then Shmmax_req="$col4"
fi
done <sapconf.csv


while IFS=, read -r col1 col2 col3 col4 col5;
do
     if [[ "$col1" == $ts && "$col2" =~ "PAS" && "$col3" =~ "TMPFS_SIZE" ]];
        then Tmpfs_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "pas" && "$col3" =~ "TMPFS_SIZE" ]];
        then Tmpfs_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "db" && "$col3" =~ "TMPFS_SIZE" ]];
        then Tmpfs_req="$col4"
     elif [[ "$col1" == $ts && "$col2" =~ "DB" && "$col3" =~ "TMPFS_SIZE" ]];
        then Tmpfs_req="$col4"

fi
done <sapconf.csv


#if [[ $virtual == *"pas"* ]];
#then {
#  echo "$TMPFS_SIZE"
#echo "$SHMALL"
#echo "$SHMMAX"
#echo "$SEMMSL"
#echo "$SEMMNS"
#echo "$SEMOPM"
#echo "$SEMMNI"
#echo "$MAX_MAP_COUNT"
#}>${path}/${h}.csv

#fi

#while IFS= read -r line;
#do
#    if [[ "$substring" == ${virtual:0:3} ]];
#        then REQ="[$line]"
#fi
#done < requirements.csv

TMPFS_SIZE_FINAL=$(if [ $TMPFS_SIZE -ge $Tmpfs_req ]; then echo "Pass"; else echo "Failed";fi)
SHMALL_FINAL=$(if [ $SHMALL -ge $Shmall_req ]; then echo "Pass"; else echo "Failed"; fi)
SHMMAX_FINAL=$(if [ $SHMMAX -ge $Shmmax_req ]; then echo "Pass"; else echo "Failed"; fi)
SEMMSL_FINAL=$(if [ $SEMMSL -ge $Semmsl_req ]; then echo "Pass"; else echo "Failed"; fi)
SEMMNS_FINAL=$(if [ $SEMMNS -ge $Semmns_req ]; then echo "Pass"; else echo "Failed"; fi)
SEMOPM_FINAL=$(if [ $SEMOPM -ge $Semopm_req ]; then echo "Pass"; else echo "Failed"; fi)
SEMMNI_FINAL=$(if [ $SEMMNI -ge $Semmni_req ]; then echo "Pass"; else echo "Failed"; fi)
MAX_FINAL=$(if [ $MAX_MAP_COUNT -ge $Max_count_req ]; then echo "Pass"; else echo "Failed"; fi)
NO_FILES_FINAL=$(if [ $No_files -ge $No_files_req ]; then echo "Pass"; else echo "Failed"; fi)
MAX_PROC_FINAL=$(if [ $Max_proc -ge $Max_proc_req ]; then echo "Pass"; else echo "Failed"; fi)


{
#echo "System Name, Virtual Hostname/Physical Hostname, Paramters, Actual Output, Required Output, Status"
#if [ "${hs}.${dn}" != "${hl}" -o "${hs}" != ${h} ]; then
#    echo "${ts},$virtual/${h},/hostname settings are wrong, failed, directory path does not exist"
#else
#    echo "${ts},$virtual/${h},/etc/sysconfig/network settings, passed, directory path exist"
#fi

#if [ "$(hostname -f)" == "${hl}" ] && [ $fix_localhost -eq 0 ] && [ $num_ip -eq 7 ]; then
#         echo "${ts},$virtual/${h},/etc/hosts, passed, directory path exist"
#else
#         echo "${ts},$virtual/${h},/etc/hosts checking, failed, directory path does not exist"
#fi

#SAP_LDAP1= [ -d "/usr/lib64/libldap.so.199" ] && echo "${ts},$virtual/${h},Directory /usr/lib64/libldap.so.199, passed, directory path exist" || echo "${ts},$virtual/${h},Directory /usr/lib64/libldap.so.199, failed, directory path does not exist"
#SAP_LDAP2= [ -d "/usr/lib64/liblber.so.199" ] && echo "${ts},$virtual/${h},Directory /usr/lib64/liblber.so.199, passed, directory path exist" || echo "${ts},$virtual/${h},Directory /usr/lib64/liblber.so.199, failed, directory path does not exist"

#SAP_old= [ -d "/usr/lib/libstdc++-libc6.1-1.so.3" ] && echo "${ts},$virtual/${h},Directory /usr/lib/libstdc++-libc6.1-1.so.3, passed, directory path exist" || echo "${ts},$virtual/${h},Directory /usr/lib/libstdc++-libc6.1-1.so.3, failed, directory path does not exist"
#NTP_Service1= systemctl status chronyd.service

echo "${ts}, $virtual/${h}, TMPFS_SIZE, $TMPFS_SIZE, $Tmpfs_req, $TMPFS_SIZE_FINAL"
echo "${ts}, $virtual/${h}, SHMALL, $SHMALL, $Shmall_req, $SHMALL_FINAL"
echo "${ts}, $virtual/${h}, SHMMAX, $SHMMAX, $Shmmax_req, $SHMMAX_FINAL"
echo "${ts}, $virtual/${h}, SEMMSL, $SEMMSL, $Semmsl_req, $SEMMSL_FINAL"
echo "${ts}, $virtual/${h}, SEMMNS, $SEMMNS, $Semmns_req, $SEMMNS_FINAL"
echo "${ts}, $virtual/${h}, SEMOPM, $SEMOPM, $Semopm_req, $SEMPOM_FINAL"
echo "${ts}, $virtual/${h}, SEMMNI, $SEMMNI, $Semmni_req, $SEMMNI_FINAL"
echo "${ts}, $virtual/${h}, MAX_MAP_COUNT,$MAX_MAP_COUNT, $Max_count_req, $MAX_FINAL"

#UUID= systemctl status uuidd.service
#echo "GLIBC PACKAGE..."
#echo "Major version: $MAJOR_VERSION / Required: $REQUIRED_MAJOR_VERSION"

Active='active (running)'
if [[ "$(systemctl status chronyd.service)"  =~  "$Active" ]];
 then echo "${ts}, $virtual/${h}, NTP Service, Active and running, Null, Pass"
else echo "${ts}, $virtual/${h}, NTP Service, Non-Active, Null, Failed"
fi

if [[ "$(systemctl status uuidd.service)" =~ "$Active" ]];
then echo "${ts}, $virtual/${h}, UUID, Active and running, Null, Pass"
else echo "${ts}, $virtual/${h}, UUID, Non-active, Null, Failed"
fi
#echo "The following required glibc version is already installed, $ARCHITECTURE"

echo "${ts}, $virtual/${h}, Number of files (descriptors), $No_files, $No_files_req, $NO_FILES_FINAL"
echo "${ts}, $virtual/${h}, Max proc, $Max_proc, $Max_proc_req, $MAX_PROC_FINAL"
#echo "Server name:  $(hostname -f)"


#s=$(env)
#files='SAPSYSTEMNAME'

#if [[ ""${s##*$files}" | awk 'match($0,"="){print substr($0,RSTART+1,4)}'" =~ "Y08" ]];
#then echo "success"
#else echo "failed"
#fi
}>> sapconf.csv
sort -u sapconf.csv -o sapconf.csv
{
echo "SAPSYSTEMNAME:${ts}, Virtual/Physical Hostname: $virtual/${h}, TMPFS_SIZE: $TMPFS_SIZE, TMPFS_REQ: $Tmpfs_req, Status: $TMPFS_SIZE_FINAL"
echo "SAPSYSTEMNAME:${ts}, Virtual/Physical Hostname: $virtual/${h}, SHMALL: $SHMALL, SHAMLL_REQ: $Shmall_req, Status: $SHMALL_FINAL"
echo "SAPSYSTEMNAME:${ts}, Virtual/Physical Hostname: $virtual/${h}, SHMMAX: $SHMMAX, SHMMAX_REQ: $Shmmax_req, Status: $SHMMAX_FINAL"
echo "SAPSYSTEMNAME:${ts}, Virtual/Physical Hostname: $virtual/${h}, SEMMSL: $SEMMSL, SEMMSL_REQ: $Semmsl_req, Status: $SEMMSL_FINAL"
echo "SAPSYSTEMNAME:${ts}, Virtual/Physical Hostname: $virtual/${h}, SEMMNS: $SEMMNS, SEMMNS_REQ: $Semmns_req, Status: $SEMMNS_FINAL"
echo "SAPSYSTEMNAME:${ts}, Virtual/Physical Hostname: $virtual/${h}, SEMOPM: $SEMOPM, SEMOPM_REQ: $Semopm_req, Status: $SEMOPM_FINAL"
echo "SAPSYSTEMNAME:${ts}, Virtual/Physical Hostname: $virtual/${h}, SEMMNI: $SEMMNI, SEMNI_REQ: $Semmni_req, Status: $SEMMNI_FINAL"
echo "SAPSYSTEMNAME:${ts}, Virtual/Physical Hostname: $virtual/${h}, MAX_MAP_COUNT: $MAX_MAP_COUNT, MAX_COUNT_REQ: $Max_count_req, Status: $MAX_FINAL"
echo "SAPSYSTEMNAME:${ts}, Virtual/Physical Hostname: $virtual/${h}, Number of files: $(ulimit -n), NO_FILES_REQ: $No_files_req, Status: $NO_FILES_FINAL"
echo "SAPSYSTEMNAME:${ts}, Virtual/Physical Hostname: $virtual/${h}, Max Proc: $(ulimit -u), MAX_PROC_REQ: $Max_proc_req, Status: $MAX_PROC_FINAL"
}>${path}.txt

echo "SAPCONF script ran successfully!"
