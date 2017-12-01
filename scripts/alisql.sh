#!/bin/sh

alisql_url=https://github.com/alibaba/AliSQL/archive/AliSQL-5.6.32-1.tar.gz
#alisql_src=${alisql_url##*/}
alisql_src=AliSQL-AliSQL-5.6.32-1.tar.gz
alisql_src_dir=${alisql_src%\.*}
alisql_src_dir=${alisql_src_dir%\.*}
alisql=AliSQL-5.6.32-1.tar.gz
alisql_dir=${alisql%\.*}
alisql_dir=${alisql_dir%\.*}

function alisql_installed {
	[ -e $topdir/install/$alisql_dir/bin/mysqld ]
}

function prepare_alisql {
	yum install -y ncurses-devel
}

function build_alisql {
		#-DMYSQL_USER=mysql  \
		#-DWITH_MEMORY_STORAGE_ENGINE=1 \
	if [ ! -d $topdir/build/$alisql_dir ]; then
		if [ ! -e $topdir/pkgs/$alisql_src ]; then
			info "download $alisql_src ..."
			wget $alisql_url -O $topdir/pkgs/$alisql_src
		fi
		tar xf $topdir/pkgs/$alisql_src -C $topdir/build
	fi

	info "install ${alisql_src} dependency ..."
	prepare_alisql

	pushd $topdir/build/$alisql_src_dir/BUILD
	sh autorun.sh
	cd ..
	rm -rf build_alisql && mkdir build_alisql && cd build_alisql
	cmake .. -DCMAKE_INSTALL_PREFIX=$topdir/install/$alisql_dir \
		-DMYSQL_DATADIR=$topdir/install/$alisql_dir/data \
		-DSYSCONFDIR=$topdir/install/etc \
		-DWITH_MYISAM_STORAGE_ENGINE=1 \
		-DWITH_INNOBASE_STORAGE_ENGINE=1 \
		-DMYSQL_UNIX_ADDR=$topdir/install/$alisql_dir/run/mysql.sock \
		-DMYSQL_TCP_PORT=3306 \
		-DENABLED_LOCAL_INFILE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 \
		-DEXTRA_CHARSETS=all \
		-DDEFAULT_CHARSET=utf8 \
		-DDEFAULT_COLLATION=utf8_general_ci
	make -j64
	make install
	popd
}

function configure_alisql {
	if ! grep -q "mysql" /etc/passwd; then
		groupadd mysql
		useradd -g mysql mysql
	fi

	if ! grep -q "alisql_home" $topdir/install/etc/profile; then
		append "export alisql_home=$topdir/install/$alisql_dir"
	fi
}

function install_alisql {
	if alisql_installed; then
		info "$alisql_dir already installed"
		return
	fi

	build_alisql
	configure_alisql
}
