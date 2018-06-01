#!/bin/bash

# Instructions:
#
# https://github.com/strongswan/strongswan

msg() {
	echo >&2 $0: $@
}

die() {
	msg $@
	exit 1
}

source ./conf.sh || die "unable to load config: ./conf.sh"

msg will issue ca_key=$ca_key
msg will issue ca_cert=$ca_cert

[ -f $ca_key ] && die refusing to overwrite existing ca_key=$ca_key
[ -f $ca_cert ] && die refusing to overwrite existing ca_cert=$ca_cert

$pki --gen --type ed25519 --outform pem > $ca_key || die failure issuing ca_key=$ca_key
$pki --self --ca --lifetime 3652 --in $ca_key --dn "C=CH, O=$ca_name, CN=$ca_name Root CA" --outform pem > $ca_cert || die failure issuing ca_cert=$ca_cert

msg copy these files to both vpn gateways:
msg issued ca_key=$ca_key
msg issued ca_cert=$ca_cert
