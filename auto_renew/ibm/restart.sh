ibm_info() {
inf=$(awk -F ":" '{print $2}' $1)
inf_array=($inf)
region=${inf_array[0]}
account=${inf_array[1]}
passwd=${inf_array[2]}
appname=${inf_array[3]}
platform=${inf_array[4]}
}
ibm_restart() {
/usr/local/bin/cf l -a https://api.${region}.cf.cloud.ibm.com login -u ${account} -p ${passwd} && /usr/local/bin/cf rs ${appname}
}
#ibm_restart $1
