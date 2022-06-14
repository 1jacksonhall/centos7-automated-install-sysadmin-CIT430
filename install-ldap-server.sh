#! /bin/bash
#Group 3 LDAP Server Install Script
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
                        echo "This script installs LDAP"; exit
                        ;;
                \?)
                        echo "invalid argument -$OPTARG"; exit
                        ;;
        esac
done

#installs setup software
yum install openldap-servers -y
yum install openldap-clients -y

#configure DNS name for LDAP server
sed -i '8s/.*/olcSuffix: dc=team3,dc=nku,dc=edu/' /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif
sed -i '9s/.*/olcRootDN: cn=Manager,dc=team3,dc=nku,dc=edu/' /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif

#salted password
saltedpass=$(slappasswd -h {SSHA} -s test)
echo "olcRootPW: $saltedpass" >> /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif

#start LDAP Server on boot
systemctl enable slapd

firewall-cmd --zone=public --add-port=389/tcp --permanent
firewall-cmd --zone=public --add-port=636/tcp --permanent
firewall-cmd --reload

#authentication
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
yum install nss_ldap -y
yum install migrationtools -y

#edits migrate_common.ph file
sed -i '70s/.*/$DEFAULT_MAIL_DOMAIN = "team3.nku.edu";' /usr/share/migrationtools/migrate_common.ph
sed -i '73s/.*/$DEFAULT_BASE = "dc=team3,dc=nku,dc=edu";' /usr/share/migrationtools/migrate_common.ph

#creation of base.ldif file
echo "dn: dc=team3,dc=nku,dc=edu" >> /usr/share/migrationtools/base.ldif
echo "dc: team3" >> /usr/share/migrationtools/base.ldif
echo "objectClass: top" >> /usr/share/migrationtools/base.ldif
echo "objectClass: domain" >> /usr/share/migrationtools/base.ldif
echo "" >> /usr/share/migrationtools/base.ldif
echo "dn: ou=People,dc=team3,dc=nku,dc=edu" >> /usr/share/migrationtools/base.ldif
echo "ou: People" >> /usr/share/migrationtools/base.ldif
echo "objectClass: top" >> /usr/share/migrationtools/base.ldif 
echo "objectClass: organizationalUnit" >> /usr/share/migrationtools/base.ldif
echo "" >> /usr/share/migrationtools/base.ldif
echo "dn: ou=Group,dc=team3,dc=nku,dc=edu" >> /usr/share/migrationtools/base.ldif
echo "ou: Group" >> /usr/share/migrationtools/base.ldif
echo "objectClass: top" >> /usr/share/migrationtools/base.ldif
echo "objectClass: organizationalUnit" >> /usr/share/migrationtools/base.ldif

slapadd -v -l base.ldif

#changes owner of /var/lib/ldap
chown -R ldap:ldap /var/lib/ldap
systemctl start slapd.service

#adds external
ldapadd -Y EXTERNAL -H ldapi:// -f /etc/openldap/schema/core.ldif
ldapadd -Y EXTERNAL -H ldapi:// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:// -f /etc/openldap/schema/inetorgperson.ldif

systemctl stop slapd.service
chown -R ldap:ldap /var/lib/ldap

#migrates passwd/group into ldap
./usr/share/migrationtools/migrate_passwd.pl /etc/passwd > /usr/share/migrationtools/passwd.ldif
slapadd -v -l /usr/share/migrationtools/passwd.ldif

./usr/share/migrationtools/migrate_group.pl /etc/group > /usr/share/migrationtools/group.ldif
slapadd -v -l /usr/share/migrationtools/group.ldif

chown -R ldap:ldap /var/lib/ldap
systemctl start slapd.service

#diradm installation
cd /usr/local
wget http://www.hits.at/diradm/diradm-1.3.tar.gz
tar zxvf diradm-1.3.tar.gz
cp /usr/local/diradm-1.3/diradm.conf /etc/

sed -i '6s/.*/BINDDN="dc=team3,dc=nku,dc=edu"/' /etc/diradm.conf
sed -i '10s/.*/USERBASE="dc=team3,dc=nku,dc=edu"/' /etc/diradm.conf
sed -i '11s/.*/GROUPBASE="dc=team3,dc=nku,dc=edu"/' /etc/diradm.conf

echo "Program has finished"
