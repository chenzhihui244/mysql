#!/bin/bash

mariadb_path=/home/mariadb
mariadb_conf=${mariadb_path}/etc/my.cnf
# init database instance
mysql_install_db --basedir=/usr --datadir=${mariadb_path}/data --user=mysql
# start database instance
mysqld_safe --defaults-file=${mariadb_conf}

# test database inst
mariadb_user=root
mariadb_pass=123456
mariadb_sock=${mariadb_path}/socket/mysql.sock
mysqladmin -u${mariadb_user} -S${mariadb_sock} ping

# set passwd
mysqladmin -u${mariadb_user} -S ${mariadb_sock} password "${mariadb_pass}"

mysql -u${mariadb_user} -p${mariadb_pass} -S${mariadb_sock} -e "show databases;"

mysqladmin create sbtest -u${mariadb_user} -p${mariadb_pass} -S ${mariadb_sock}

mysql -u${mariadb_user} -p${mariadb_pass} -S ${mariadb_sock} -e "grant all privileges on *.* to ${mariadb_user}@'%' identified by '${mariadb_pass}' with grant option;" mysql

mysql -u${mariadb_user} -p${mariadb_pass} -S ${mariadb_sock} -e "flush privileges;" mysql

mysql -h ${HOST} -P ${PORT} -u${mariadb_user} -p${mariadb_pass} -e "show databases;"
mysql -h ${HOST} -P ${PORT} -u${mariadb_user} -p${mariadb_pass} -e "use sbtest; show tables;"
