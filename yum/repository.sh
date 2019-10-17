#!/bin/sh

yum -y update
yum install -y epel-release
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
