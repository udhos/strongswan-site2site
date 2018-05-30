#!/bin/sh

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

if [ $# -ne 7 ]; then
	cat >&2 <<__EOF__
usage:   $0 host              host_other        label       label_other subnet         subnet_other   ip_other
example: $0 vpngw-aws         vpngw-openstacktb aws         openstacktb 10.73.0.0/26   10.155.19.0/24 10.75.32.17
         $0 vpngw-openstacktb vpngw-aws         openstacktb aws         10.155.19.0/24 10.73.0.0/26   10.73.31.107
__EOF__
	exit 2
fi

host=$1
host_other=$2
label=$3
label_other=$4
subnet=$5
subnet_other=$6
ip_other=$7

source ./conf.sh || die "unable to load config: ./conf.sh"

key=$private/${label}Key.pem
req=$etc/${label}Req.pem
cert=$etc/swanctl/x509/${label}Cert.pem
cert_other=$etc/swanctl/x509/${label_other}Cert.pem

[ -r $ca_cert ] || die missing ca_cert=$ca_cert
[ -r $ca_key ] || die missing ca_key=$ca_key

msg will issue key=$key
msg will issue req=$req
msg will issue cert=$cert
msg will issue ipsec_conf=$ipsec_conf
msg will issue swanctl_conf=$swanctl_conf

[ -f $key ] && die refusing to overwrite key=$key
[ -f $req ] && die refusing to overwrite req=$req
[ -f $cert ] && die refusing to overwrite cert=$cert
[ -f $ipsec_conf ] && die refusing to overwrite ipsec_conf=$ipsec_conf
[ -f $swanctl_conf ] && die refusing to overwrite swanctl_conf=$swanctl_conf

$pki --gen --type ed25519 --outform pem > $key
$pki --req --type priv --in $key --dn "C=CH, O=strongswan, CN=$host" --san $host --outform pem > $req
$pki --issue --cacert $ca_cert --cakey $ca_key --type pkcs10 --in $req --serial 01 --lifetime 3650 --outform pem > $cert

cat > $ipsec_conf <<__EOF__ || die could not issue ipsec_conf=$ipsec_conf
config setup

conn sts-base
    fragmentation=yes
    dpdaction=restart
    ike=aes192gcm16-aes128gcm16-prfsha256-ecp256-ecp521,aes192-sha256-modp3072,default
    esp=aes192gcm16-aes128gcm16-prfsha256-ecp256-modp3072,aes192-sha256-ecp256-modp3072#
    keyingtries=%forever
    leftid=$host
    leftcert=$cert

conn net-net
    also=sts-base
    keyexchange=ikev2
    leftsubnet=$subnet
    rightsubnet=$subnet_other
    right=$ip_other
    rightcert=$cert_other
    auto=start
__EOF__

cat > $swanctl_conf <<__EOF__ || die could not issue swanctl_conf=$swanctl_conf
connections {
        net-net {
                remote_addrs = $ip_other
                proposals = aes128-sha256-x25519

                local {
                        auth = pubkey
                        certs = $cert
                        id = $host
                }
                remote {
                        auth = pubkey
                        certs = $cert_other
                        id = $host_other
                }
                children {
                        net-net {
                                local_ts  = $subnet
                                remote_ts = $subnet_other
                                dpd_action = restart
                                start_action = trap
                                updown = $prefix/libexec/ipsec/_updown iptables
                                esp_proposals = aes128gcm128-x25519
                        }
                }
        }
}

authorities {
    $ca_name {
        cacert = $ca_cert
        file = $ca_cert
    }
}

include conf.d/*.conf
__EOF__

msg issued key=$key
msg issued req=$req
msg issued cert=$cert
msg issued ipsec_conf=$ipsec_conf
msg issued swanctl_conf=$swanctl_conf
msg -- remember to copy cert_other=$cert_other to this host
msg -- start tunnel with:
msg $prefix/sbin/ipsec start
msg $prefix/sbin/swanctl --load-all
msg $prefix/sbin/swanctl --stats
msg $prefix/sbin/ipsec up net-net
msg $prefix/sbin/ipsec route net-net
msg $prefix/sbin/ipsec status

