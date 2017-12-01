#!/bin/sh

function info {
	echo >&2 "$@"
}

function warn {
	info "exec command ($@) ..."
	if ! eval "$@"; then
		info "WARNING: command ($@) failed!"
		exit 1
	fi
}

function append {
	echo "$@" >> $topdir/install/etc/profile
}
