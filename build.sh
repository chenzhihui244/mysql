#!/bin/sh

topdir=$(cd `dirname $0`; pwd)

mkdir -p $topdir/{build,pkgs,install}
mkdir -p $topdir/install/etc

if [ ! -e $topdir/install/etc/profile ]; then
	echo "export topdir=$topdir" > $topdir/install/etc/profile
fi

. scripts/alisql.sh
. scripts/tcprstat.sh

install_alisql
install_tcprstat
