#! /bin/bash
#client installation file for project 3

#monit installation
yum install epel-release -y
yum install monit -y

#gets client monitrc from server
wget http://SERVERIP/project3/monitrc-client
mv -f monitrc-client /etc/monitrc

#used for nfs monit tests
touch /tmp/nfs-test.sh
printf "#! /bin/bash\ndf -h | grep /home" >> /tmp/nfs-test.sh

#used for ldap monit tests
touch /tmp/ldap-test.sh
printf "#! /bin/bash\nldapsearch -x -LL -b '' -s base '(objectclass=*)' namingContexts" >> /tmp/ldap-test.sh

systemctl enable monit
systemctl restart monit


#syslog forwarding to server
sed -i '84s/.*/$ActionQueueFileName fwdRule1/' /etc/rsyslog.conf
sed -i '85s/.*/$ActionQueueMaxDiskSpace 1g/' /etc/rsyslog.conf
sed -i '86s/.*/$ActionQueueSaveOnShutdown on/' /etc/rsyslog.conf
sed -i '87s/.*/$ActionQueueType LinkedList/' /etc/rsyslog.conf
sed -i '88s/.*/$ActionResumeRetryCount -1/' /etc/rsyslog.conf
sed -i "90s/.*/*.* @$1:514/" /etc/rsyslog.conf
systemctl restart rsyslog
