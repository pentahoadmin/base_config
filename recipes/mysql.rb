#############################################################################
# Cookbook Name:: base_config
# Recipe:: mysql
#
# Copyright 2017, Pentaho, A Hitachi Group Company
#
# All rights reserved - Do Not Redistribute
#############################################################################
mysqlpass = 'password'
user = 'root'
host = '127.0.0.1'
port = '3306'
table = 'test'
db = 'mysql'

mysql_service 'mysqld' do
  initial_root_password mysqlpass["password"]
  action [:create, :start]
end

package 'mysql-connector-java'

execute 'create-test-database' do
  command "mysql -u #{user} -P #{port} -h #{host} -p#{mysqlpass} -e \"create database #{table};\""
  not_if "mysql -u #{user} -P #{port} -h #{host} -p#{mysqlpass} --e \"SHOW DATABASES\" |grep #{table}"
  notifies :run, "execute[mysql-flush-privs]", :delayed
end

execute 'grant_privileges_to_root' do
  #command "mysql -u #{user} -P #{port} -h #{host} -p#{mysqlpass} -e \"use mysql;\""  command "mysql -u #{user} -P #{port} -h #{host} -p#{mysqlpass} -e \"grant all on *.* to 'root'@'%' identified by 'password';\""
  command "mysql -u #{user} -P #{port} -h #{host} -p#{mysqlpass} -e \"use mysql; grant all on *.* to 'root'@'%' identified by 'password';\""
  not_if "mysql -u #{user} -P #{port} -h #{host} -p#{mysqlpass} -e \"use mysql; select host, user, password from user WHERE host LIKE '\%';\""
  notifies :run, "execute[mysql-flush-privs]", :delayed
end

# Flush mysql privs if any are changed
execute 'mysql-flush-privs' do
  command "mysql -u #{user} -P #{port} -h #{host} -p#{mysqlpass} -D #{db} -e \"FLUSH PRIVILEGES;\""
  action :nothing
end
