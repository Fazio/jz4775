#!/bin/bash
set -x
type=$1
freq=$2
mode=$3
date=`date`
cg_path="./sources/meta-antminer/recipes-bitmianer/cgminer"
config_path="./sources/meta-antminer/recipes-bitmianer/initscripts/initscripts-1.0"
cgminer_name=cgminer
image_name=""

MACHINE="ci20" ./oebb.sh config ci20

ps -aux | grep bitbake |awk {'print $2'} | xargs kill -9

sed -i -r "s/^BUILD_DATE = \".*\"/\BUILD_DATE = \"$date\"/g" ./conf/local.conf

if [ x${type} == "xL3" ];then
	cgminer_name=cgminer-l3
	image_name=L3
	
	sed -i -r "s/^Miner_TYPE = \".*\"/\Miner_TYPE = \"L3\"/g" ./conf/local.conf
	sed -i -r "s/\"bitmain-freq\" : \".*\"/\"bitmain-freq\" : \"$freq\"/g" $config_path/cgminer_l3.conf.factory
fi

if [ x${type} == "xL3+" ];then
	cgminer_name=cgminer-l3p
	image_name=L3+
	
	sed -i -r "s/^Miner_TYPE = \".*\"/\Miner_TYPE = \"L3+\"/g" ./conf/local.conf
	sed -i -r "s/\"bitmain-freq\" : \".*\"/\"bitmain-freq\" : \"$freq\"/g" $config_path/cgminer_l3.conf.factory
fi

if [ x${type} == "xD3" ];then
	cgminer_name=cgminer-dash
	image_name=D3
	
	sed -i -r "s/^Miner_TYPE = \".*\"/\Miner_TYPE = \"D3\"/g" ./conf/local.conf
	sed -i -r "s/\"bitmain-freq\" : \".*\"/\"bitmain-freq\" : \"$freq\"/g" $config_path/cgminer_d1.conf.factory
fi


if [ x${mode} == "xSD" ];then
	sed -i -r "s/^BOOT_MODE = \".*\"/\BOOT_MODE = \"SD\"/g" ./conf/local.conf
else	
	sed -i -r "s/^BOOT_MODE = \".*\"/\BOOT_MODE = \"NAND\"/g" ./conf/local.conf
fi

. environment-angstrom-v2014.12

if [ x"" == x$image_name ];then
	echo -e "\033[31m Miner type is not configured \033[0m"
	exit -1	
fi

sed -i -r "s/.*?echo \".*?\" > .*?compile_time/        echo \"$date\" > \${D}\${bindir}\/compile_time/g" ./sources/meta-antminer/recipes-bitmianer/initscripts/initscripts_1.0.bbappend
sed -i -r "s/.*?echo \".*?\" >> .*?compile_time/        echo \"Antminer $type\" >> \${D}\${bindir}\/compile_time/g" ./sources/meta-antminer/recipes-bitmianer/initscripts/initscripts_1.0.bbappend


if [ x"$4" != x"init" ];then
bitbake -c clean initscripts -f
bitbake -c clean lighttpd -f
bitbake -c clean $cgminer_name -f
bitbake -c clean sysvinit-inittab -f
fi

rm -rf ./build/tmp-angstrom_v2014_12-glibc/work/mips32r2el-angstrom-linux/initscripts

bitbake $image_name -f


cp ./deploy/glibc/images/ci20/Angstrom-antminer_m-glibc-ipk-v2014.12-ci20.rootfs.cpio.gz.u-boot ./image_items/initramfs.bin.SD
cd image_items
rm -rf *.tar.gz
c_time=`date "+%Y%m%d%H%M"`
file_name="Antminer-${type}-${c_time}-${freq}M.tar.gz"
tar -zcvf "$file_name" *

