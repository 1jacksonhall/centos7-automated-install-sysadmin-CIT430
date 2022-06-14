#! /bin/bash
#Group 3 NFS Server Install Script
#CIT 470-001 - Darci Guriel
#October 21, 2018
#Jackson Hall, Nicholas Johnson, Simon Bihl, Ali Qahsan, and Nathaniel Thurman

#displays help if -h or --help is used
args=( )
for arg; do
        case "$arg" in
                --help)         args+=( -h ) ;;
                *)              args+=( "$arg" ) ;;
        esac
done
set -- "${args[@]}"

while getopts ":h" opt; do
        case ${opt} in
                h)
                        echo "This script installs NFS"; exit
                        ;;
                \?)
                        echo "invalid argument -$OPTARG"; exit
                        ;;
        esac
done

#sets up /home partition
echo -e "n\np\n\n\n+8G\nw" | fdisk /dev/sda
partprobe /dev/sda
mkfs.xfs /dev/sda4 -f

#sets the created /home partition in fstab and then mounts it
echo "/dev/sda4 /home	xfs	defaults		0 0" >> /etc/fstab
mount /dev/sda4

#puts /home in exports file
echo "/home 10.2.6.0/23(rw)" >> /etc/exports

#installs nfs-utils
yum install nfs-utils -y
exportfs -a

#starts nfs services
systemctl enable nfs
systemctl start nfs
rpcbind
rpc.mountd
rpc.nfsd
rpc.rquotad
rpc.idmapd

#firewall to allow clients to use nfs
firewall-cmd --zone=public --add-port=2049/tcp --permanent
firewall-cmd --zone=public --add-port=111/tcp --permanent
firewall-cmd --zone=public --add-port=20048/tcp --permanent
firewall-cmd --zone=public --add-port=2049/udp --permanent
firewall-cmd --zone=public --add-port=111/udp --permanent
firewall-cmd --zone=public --add-port=20048/udp --permanent
firewall-cmd --reload
