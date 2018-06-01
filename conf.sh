#!/bin/sh

# Instructions:
#
# https://github.com/strongswan/strongswan

prefix=/usr/local/strongswan
etc=$prefix/etc
pki=$prefix/bin/pki
private=$etc/swanctl/private
ca_name=strongswan
ca_key=$private/strongswanKey.pem
ca_cert=$etc/swanctl/x509ca/strongswanCert.pem
ipsec_conf=$etc/ipsec.conf
swanctl_conf=$etc/swanctl/swanctl.conf
strongswan_conf=$etc/strongswan.conf
