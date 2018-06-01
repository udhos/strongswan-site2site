# strongswan-site2site

- Disable antispoofing on instances:

Disable Source/Destination check on AWS instance.

Disable antispoofing on OpenStack instance by adding address pairs to instance network port.

- Enable IP forwarding on instances:

    sudo sysctl -w net.ipv4.ip_forward=1
    sudo sed -i -e 's/^net.ipv4.ip_forward.*//g' /etc/sysctl.conf
    sudo echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
    sudo sysctl -p 

- Install StrongSWAN:

    wget https://download.strongswan.org/strongswan-5.6.3.tar.bz2
    tar xf strongswan-5.6.3.tar.bz2
    cd strongswan-5.6.3
    ./configure --prefix=/usr/local/strongswan
    make
    sudo make install

- Create the CA certificate only once:

    ./generate-ca.sh

- Copy the CA certificate to both gateways:

    /usr/local/strongswan/etc/swanctl/private/strongswanKey.pem
    /usr/local/strongswan/etc/swanctl/x509ca/strongswanCert.pem

The CA certificate is actually required on both gateways.
The CA key is needed only to create the gateway certificate in the next step.

- Generate a certificate for each gateway:

Example for aws gateway:

    # aws gateway:
    ./generate-conf.sh vpngw-aws         vpngw-openstacktb aws         openstacktb 10.73.0.0/26   10.155.19.0/24 10.75.32.17

Example for openstack gateway:

    # openstack gateway:
    ./generate-conf.sh vpngw-openstacktb vpngw-aws         openstacktb aws         10.155.19.0/24 10.73.0.0/26   10.73.31.107

- Copy each gateway certificate to the other gateway:

Each gateway should have these two certificates:

    /usr/local/strongswan/etc/swanctl/x509/awsCert.pem
    /usr/local/strongswan/etc/swanctl/x509/openstacktbCert.pem

- Start the tunnel:

    /usr/local/strongswan/sbin/ipsec start
    /usr/local/strongswan/sbin/swanctl --load-all

    /usr/local/strongswan/sbin/ipsec status
    /usr/local/strongswan/sbin/swanctl --stats

- Install as service:

    sudo cp strongswan-5.6.3/init/systemd/strongswan.service /lib/systemd/system
    systemctl enable strongswan
    systemctl start strongswan

-x-

