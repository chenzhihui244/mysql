#!/bin/sh

topdir=$(cd `dirname $0`; pwd)

mkdir -p $topdir/{build,pkgs,install}
mkdir -p $topdir/install/{etc,log}

if [ ! -e $topdir/install/etc/profile ]; then
	echo "export topdir=$topdir" > $topdir/install/etc/profile
fi

cd $topdir
. scripts/env.sh
. scripts/alisql.sh
. scripts/tcprstat.sh
. scripts/orzdba.sh

warn "install_alisql > $topdir/install/log/install_alisql.log"
warn "install_tcprstat > $topdir/install/log/install_tcprstat.log"
warn "install_orzdba"
