#!/bin/sh

orzdba_url=http://code.taobao.org/svn/orzdba/trunk
orzdba=orzdba.tar.gz
orzdba_dir=${orzdba%\.*}
orzdba_dir=${orzdba_dir%\.*}

function orzdba_installed {
	[ -e $topdir/install/$orzdba_dir/bin/orzdba ]
}

function perl_submodule_build {
	local src=${1%\.*}
	src=${src%\.*}
	tar xf $1
	pushd $src &&
	perl Build.PL &&
	perl ./Build  &&
	perl ./Build test
	perl ./Build install --install_base "$topdir/install/$orzdba_dir"
	popd
}

function perl_submodule_make {
	local src=${1%\.*}
	src=${src%\.*}
	tar xf $1
	pushd $src &&
	perl Makefile.PL &&
	make -j64 &&
	make test
	make DESTDIR="$topdir/install/$orzdba_dir" install
	popd
}

function build_orzdba {
	if [ ! -d $topdir/build/$orzdba ]; then
		if [ -e $topdir/pkgs/$orzdba ]; then
			tar xf $topdir/pkgs/$orzdba -C $topdir/build
		else
			wget -r -np --reject=html $orzdba_url -O $topdir/build/$orzdba_dir
		fi
	fi

	pushd $topdir/build/$orzdba_dir
	tar xf orzdba_rt_depend_perl_module.tar.gz
	cd Perl_Module
	perl_submodule_make "version-0.99.tar.gz"
	perl_submodule_make "Class-Data-Inheritable-0.08.tar.gz"
	perl_submodule_build "Module-Build-0.31.tar.gz"
	perl_submodule_build "File-Lockfile-v1.0.5.tar.gz"

	cp $topdir/patches/orzdba/orzdba.pl $topdir/install/$orzdba_dir/bin/orzdba
	popd
}

function configure_orzdba {
	return 0
}

function install_orzdba {
	if orzdba_installed; then
		info "$orzdba_dir already installed"
		return 0
	fi

	warn "build_orzdba"
}
