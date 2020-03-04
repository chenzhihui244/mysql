#!/bin/sh

mysql_version=5.7.27
mysql_src=mysql-boost-5.7.27.tar.gz
mysql_url=https://cdn.mysql.com/archives/mysql-5.7/mysql-boost-5.7.27.tar.gz
mysql_cfg=my.cnf
tpcc_src=TPCCRunner_SRC_V1.00.zip
tpcc_url=https://liquidtelecom.dl.sourceforge.net/project/tpccruner/TPCCRunner_SRC_V1.00.zip
topdir=`pwd`
srcdir=$topdir/src
builddir=$topdir/build
installdir=$topdir/install
datadir=$topdir/data
cfgdir=$topdir/conf

echo "$topdir"

prepare()
{
	mkdir -p $srcdir &&
	mkdir -p $builddir &&
	mkdir -p $installdir &&
	mkdir -p $datadir/{data,tmp,etc} &&
	install_dependency &&
	download_mysql
}

install_dependency_zypper()
{
	zypper in -y numactl
}

install_dependency_yum()
{
	yum install -y ncurses-devel
}

install_dependency()
{
	#install_dependency_zypper
	install_dependency_yum
}

download_mysql()
{
	[ -f $srcdir/$mysql_src ] || {
		cd $srcdir &&
		wget $mysql_url &&
		cd -
	}
}

download_tpccrunner()
{
	[ -f $srcdir/$tpcc_src ] || {
		cd $srcdir && wget $tpcc_url
	}
}

build_mysql() {
	echo "$0 - $FUNCNAME"
	[ -x $installdir/mysql/bin/mysqld ] && return 0

	[ -d $builddir/mysql-${mysql_version} ] || {
		tar xf $srcdir/$mysql_src -C $builddir
	}

	rm -rf $builddir/build-mysql
	mkdir -p $builddir/build-mysql &&
	cd $builddir/build-mysql &&
	cmake $builddir/mysql-${mysql_version} \
		-DCMAKE_INSTALL_PREFIX=$installdir/mysql \
		-DWITH_BOOST=$builddir/mysql-${mysql_version}/boost/boost_1_59_0 \
		-DCMAKE_C_FLAGS="-march=armv8.1-a+lse -mtune=tsv110" \
		-DCMAKE_CXX_FLAGS="-march=armv8.1-a+lse -mtune=tsv110" \
		-DWITH_EMBEDDED_SERVER=OFF &&
	make -j`nproc` &&
	make install
}

post_mysql() {
	echo "$0 - $FUNCNAME"
	[ -f ${datadir}/etc/my.cnf ] || {
		cp $cfgdir/$mysql_cfg ${datadir}/etc/my.cnf
		sed -i "s#mysql_base_dir#${installdir}/mysql#" ${datadir}/etc/my.cnf
		sed -i "s#mysql_data_dir#${datadir}#" ${datadir}/etc/my.cnf
	}

	mkdir -p $installdir/mysql/var/run/mysqld
	mkdir -p $installdir/mysql/var/log
	grep "${installdir}" /etc/profile
	[ $? -eq 0 ] || {
		java_path=`which java`
		java_path=$(readlink -f $java_path)
		java_path=${java_path%/bin/java}
		cat << EOF >> /etc/profile

JAVA_HOME=$java_path
CLASS_PATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib
PATH=${installdir}/mysql/bin:$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
export JAVA_HOME JRE_HOME CLASS_PATH PATH
EOF
	}
}

init_mysql()
{
	echo "$0 - $FUNCNAME"
	source /etc/profile

	[ -f $datadir/data/ibdata1 ] || {
		mysqld --defaults-file=${datadir}/etc/my.cnf --initialize-insecure
	}

	sleep 10
	pidof mysqld || nohup mysqld --defaults-file=${datadir}/etc/my.cnf &
	retry=0
	while (( retry < 30 )); do
		[ -e ${datadir}/mysql.sock ] && break
		sleep 10
		(( retry++ ))
	done
	#ln -sf ${datadir}/mysql.sock /tmp/mysql.sock
	mysqladmin -u root password 'root' -S ${datadir}/mysql.sock

	mysql -u root -proot -S ${datadir}/mysql.sock \
		-e "grant all privileges on *.* to tpcc@'%' identified by 'cu';"
	mysql -u root -proot -S ${datadir}/mysql.sock \
		-e "grant all privileges on *.* to tpcc@'localhost' identified by 'cu';"
	mysql -u root -proot -S ${datadir}/mysql.sock \
		-e "GRANT ALL PRIVILEGES ON *.* TO root@localhost IDENTIFIED BY 'root' WITH GRANT OPTION;"
	mysql -u root -proot -S ${datadir}/mysql.sock \
		-e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;"
	mysql -u root -proot -S ${datadir}/mysql.sock \
		-e "flush privileges;"
}

import_data()
{
	[ -d $builddir/tpccrunner ] || {
		mkdir -p $builddir/tpccrunner &&
		cd $builddir/tpccrunner &&
		unzip $srcdir/$tpcc_src
	}
	cd $builddir/tpccrunner
	mysql -utpcc -pcu -S ${datadir}/mysql.sock -vvv -n < sql/example/mysql/create_database.sql
	mysql -utpcc -pcu -S ${datadir}/mysql.sock -vvv -n < sql/example/mysql/create_table.sql
	nohup java -cp  bin/TPCC_CU_v3.jar:lib/mysql-connector-java-5.1.7-bin.jar iomark.TPCCRunner.Loader conf/example/mysql/loader.properties &
	nohup mysql -utpcc -pcu -S ${datadir}/mysql.sock -vvv -n < sql/example/mysql/create_index.sql &
	mysql -utpcc -pcu -S ${datadir}/mysql.sock -vvv -n < sql/example/mysql/chk_rlt.sql


	mysqladmin -u root -proot -S ${datadir}/mysql.sock shutdown;
}

shutdown_mysql() {
	/usr/bin/expect <<EOF
	set timeout 60
	spawn ${installdir}/mysql/bin/mysqladmin -u root -p -S ${datadir}/mysql.sock shutdown
	expect {
		"Enter password:" {send "root\r"}
	}
	expect "\[*\]" {send "\r"}
EOF
}

build_mysql2() {
	cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
		-DMYSQL_DATADIR=/home/data \
		-DSYSCONFDIR=/etc \
		-DWITH_INNOBASE_STORAGE_ENGINE=1 \
		-DWITH_PARTITION_STORAGE_ENGINE=1 \
		-DWITH_FEDERATED_STORAGE_ENGINE=1 \
		-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
		-DWITH_MYISAM_STORAGE_ENGINE=1 \
		-DENABLED_LOCAL_INFILE=1 \
		-DENABLE_DTRACE=0 \
		-DDEFAULT_CHARSET=utf8mb4 \
		-DDEFAULT_COLLATION=utf8mb4_general_ci \
		-DWITH_EMBEDDED_SERVER=1 \
		-DDOWNLOAD_BOOST=1 \
		-DWITH_BOOST=/root/MySQL/mysql-${mysql_version}/boost/boost_1_59_0
}

cleanup() {
	rm -rf $builddir
	rm -rf $installdir
	rm -rf $datadir
}

die() {
	printf "\e[31m"
	printf "$1"
	printf "\e[0m"
	printf "\n"
	exit 1
}

prepare || die "prepare failed!"
build_mysql || die "build mysql failed!"
post_mysql || die "post mysql failed!"
init_mysql || die "init database failed"

#shutdown_mysql
#cleanup
