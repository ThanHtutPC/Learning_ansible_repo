install the dns server
-----------------------
yum install bind 
yum install bind-utils

vim /etc/named 
-----------------
cp /etc/named.conf /etc/named.conf.bak 
vim /etc/named.conf

config in named.conf 
----------------------
acl AllowQuery {
        192.168.200.0/24;
        localhost;
        localnets;
};

options {
        listen-on port 53 { localnets; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        allow-query     { AllowQuery; };

        recursion yes;
		
zone "th.lab" {
        type master;
        file "db.th.lab";
};

zone "200.168.192.in-addr.arpa" {
        type master;
        file "rev.th.lab";
};

        forwarders {
                8.8.8.8;
        };
        forward only;

zone file update
------------------
vim /var/named/db.th.lab
$ORIGIN th.lab.
$TTL 86400
@         IN  SOA  server01.th.lab.  root.localhost. (
              2001062501  ; serial
              21600       ; refresh after 6 hours
              3600        ; retry after 1 hour
              604800      ; expire after 1 week
              86400 )     ; minimum TTL of 1 day
;
;
                        IN      NS      server01.th.lab.
server01                IN      A       192.168.200.231
mail                    IN      A       192.168.200.210
mail02                  IN      A       192.168.200.66

vim /var/named/rev.th.lab
$ORIGIN 200.168.192.in-addr.arpa.
$TTL 86400
@  IN  SOA  server01.th.lab.  root.localhost. (
       2001062501  ; serial
       21600       ; refresh after 6 hours
       3600        ; retry after 1 hour
       604800      ; expire after 1 week
       86400 )     ; minimum TTL of 1 day
;
@  IN  NS   server01.th.lab.

231  IN  PTR  server01.th.lab.
210  IN  PTR  mail.th.lab.
66   IN  PTR  mail02.th.lab

service restart 
------------------
systemctl restart named

add the firewall rule for node1
-----------------------------------------------------
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: cockpit dhcpv6-client dns http nfs rpc-bind ssh
  ports: 22/tcp 2049/udp 2049/tcp 111/tcp 111/udp 20048/udp 20048/tcp
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:

install the packages for nfs
-----------------------------
yum install -y nfs-utils nfs-server

config for nfs
-----------------
vim /etc/exports
/backup 192.168.200.0/255.255.255.0(rw,no_root_squash)

chmod 777 -R /backup

exportfs -arv 
exportfs -s

node2 
-------
install the packages for nfs 
----------------------------
yum install nfs-utils bind-utils -y 

showmount -e [node1.ip_address]

add firewall rule for node2 
------------------------------
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: cockpit dhcpv6-client dns http https mysql nfs rpc-bind ssh
  ports: 53/tcp 53/udp 25/tcp 110/tcp 143/tcp 465/tcp 587/tcp 993/tcp 995/tcp 4190/tcp 80/tcp 443/tcp
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:

podman login registry.redhat.io 
pomdan pull docker.io/analogic/poste.io

volume create 
-----------------
podman volume create --opt type=nfs --opt o=rw --opt device=192.168.200.231:/backup nfs_volume

podman command
----------------
podman run -d --net=host -e TZ=Asia/Yangon -v nfs_volume:/data --name "mailserver" -h mail02.th.lab -t docker.io/analogic/poste.io:latest
