#!/bin/sh

tcprstat_url=https://github.com/Lowercases/tcprstat.git
tcprstat_src=tcprstat-src.tar.gz
tcprstat=tcprstat.tar.gz

tcprstat_src_dir=${tcprstat_src%\.*}
tcprstat_src_dir=${tcprstat_src_dir%\.*}

tcprstat_dir=${tcprstat%\.*}
tcprstat_dir=${tcprstat_dir%\.*}

libpcap_url=http://www.tcpdump.org/release/libpcap-1.6.1.tar.gz
libpcap=${libpcap_url##*/}

function tcprstat_installed {
	[ -e $topdir/install/$tcprstat_dir/tcprstat ]
}

function patch_tcprstat {
	if [ ! -e $topdir/pkgs/$libpcap ]; then
		wget $libpcap_url -O $topdir/pkgs/$libpcap
	fi
	cp $topdir/pkgs/$libpcap $topdir/build/$tcprstat_src_dir/libpcap/
	rm -f $topdir/build/$tcprstat_src_dir/libpcap/libpcap-1.1.1.tar.gz
	chmod 755 $topdir/build/$tcprstat_src_dir/libpcap/resolver-patch
	sed -i "s/libpcap-1.1.1/libpcap-1.6.1/g"  $topdir/build/$tcprstat_src_dir/libpcap/resolver-patch
}

function build_tcprstat {
	if [ ! -d $topdir/build/$tcprstat_src_dir ]; then
		if [ ! -e $topdir/pkgs/$tcprstat_src ]; then
			pushd $topdir/build
			git clone $tcprstat_url $tcprstat_src_dir
			tar czf $topdir/pkgs/$tcprstat_src $tcprstat_src_dir
			popd
		else
			tar xf $topdir/pkgs/$tcprstat_src -C $topdir/build
		fi
	fi
	pushd $topdir/build/$tcprstat_src_dir
	if [ $(uname -m) == "aarch64" ]; then
		patch_tcprstat
		cp -f $topdir/patches/tcprstat/tcprstat.c $topdir/build/$tcprstat_src_dir/src/

		if [ ! -e /lib64/libc.a ]; then
			cp /lib64/libc_nonshared.a /lib64/libc.a
		fi
		if [ ! -e /lib64/libpthread.a ]; then
			cp /lib64/libpthread_nonshared.a /lib64/libpthread.a
		fi
	fi
	chmod 755 bootstrap
	./bootstrap
	if [ $(uname -m) == "aarch64" ]; then
		./configure --build=aarch64-unknown-linux-gnu --prefix=$topdir/install/$tcprstat
	else
		./configure --prefix=$topdir/install/$tcprstat
	fi
	make &&
	make install
	popd
}

function configure_tcprstat {
	return 0
}

function install_tcprstat {
	if tcprstat_installed; then
		echo "$tcprstat_src already installed"
		return 0
	fi

	build_tcprstat
	configure_tcprstat
}
