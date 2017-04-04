############################################################################
# Cookbook Name:: base_config
# Recipe:: cdh-cluster
#
# Copyright 2017, Pentaho, A Hitachi Group Company
#
# All rights reserved - Do Not Redistribute
#############################################################################
Chef::Log.info clusterhost = node['hostname']
Chef::Log.info clusterhost[0...-1]
Chef::Log.info (node['hostname'][0...-1] + "1")
Chef::Log.info node1 = (node['hostname'][0...-1] + "1")

include_recipe 'base_config::_default'

remote_file '/etc/yum.repos.d/cloudera-manager.repo' do
  source 'https://archive.cloudera.com/cm5/redhat/6/x86_64/cm/cloudera-manager.repo'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  not_if { ::File.exist?('/etc/yum.repos.d/cloudera-manager.repo') }
end

# Install cdh 5.0 packages
template '/etc/yum.repos.d/cloudera-cdh5.repo' do
  source 'cloudera-cdh5-repo.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

#%w(avro-tools crunch flume-ng hadoop-hdfs-fuse hadoop-hdfs-nfs3 hadoop-httpfs hadoop-kms hbase-solr hive-hbase hive-webhcat hue-beeswax hue-hbase hue-impala hue-pig hue-plugins hue-rdbms hue-search hue-spark hue-sqoop hue-zookeeper impala impala-shell kite llama mahout oozie pig pig-udf-datafu search sentry solr-mapreduce spark-python sqoop sqoop2 whirr).each do |pkg|
#  yum_package pkg
#end

include_recipe 'sudo::cloudera-scm'

%w(cloudera-manager-daemons cloudera-manager-server cloudera-manager-agent cloudera-manager-daemons cloudera-manager-server-db-2).each do |pkg|
  yum_package pkg
end

# Install cm 5.0 tarballs
directory '/opt/cloudera-manager' do
  owner 'cloudera-scm'
  group 'cloudera-scm'
  mode '0755'
  action :create
end

template '/etc/yum.repos.d/cloudera-cm5.repo' do
  source 'cloudera-cm5-repo.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

if `ls /opt |grep cm-5.10.0`.empty?
  remote_file '/opt/cloudera-manager/cloudera-manager-el6-cm5.10.0_x86_64.tar.gz' do
    source 'https://archive.cloudera.com/cm5/cm/5/cloudera-manager-el6-cm5.10.0_x86_64.tar.gz'
    owner 'cloudera-scm'
    group 'cloudera-scm'
    mode '0755'
    action :create
  end

  execute 'cloudera-manager-tar' do
    command 'tar xvzf /opt/cloudera-manager/cloudera-manager*.tar.gz -C /opt'
    not_if { ::Dir.exist?('/opt/cm-5.10.0') }
    notifies :run, 'execute[chown_opt_cloudera]', :immediately
    notifies :run, 'execute[chown_cm-5.10.0]', :immediately
    notifies :run, 'execute[chown_opt]', :immediately
  end
end

execute 'chown_opt_cloudera' do
  command 'chown -R cloudera-scm:cloudera-scm /opt/cloudera'
  action :nothing
end

execute 'chown_cm-5.10.0' do
  command 'chown -R cloudera-scm:cloudera-scm /opt/cm-5.10.0'
  action :nothing
end

execute 'chown_opt' do
  command 'chown root:root /opt'
  user 'root'
  action :nothing
end

template '/etc/default/cloudera-scm-server' do
  source 'cloudera-scm-server.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/default/cloudera-scm-agent' do
  source 'cloudera-scm-agent.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

directory '/opt/cloudera/parcels' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template '/etc/cloudera-scm-agent/config.ini' do
  source 'cloudera-scm-agent-config-ini.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
      #:ipmgrsrv => %x( cat /etc/hosts |grep `hostname |head -c -2`1 |awk '{print $1}' ) 
      :ipmgrsrv => ( (node['hostname'][0...-1] + "1") ) 
  )
end

service 'cloudera-scm-server-db' do
  supports :status => true, :start => true, :stop => true, :restart => true
  action [ :enable, :start]
end

service 'cloudera-scm-server' do
  supports :status => true, :start => true, :stop => true, :restart => true
  action [ :enable, :start]
end

service 'cloudera-scm-agent' do
  supports :status => true, :start => true, :stop => true, :restart => true
  action [ :enable, :start]
end

include_recipe 'base_config::mysql'

if node['hostname'] == (node['hostname'][0...-1] + "1")
  %w(zookeeper hadoop-yarn-resourcemanager).each do |pkg|
    yum_package pkg
  end
end

execute 'chown_cm-5.10.0' do
  command 'chown -R cloudera-scm:cloudera-scm /opt/cm-5.10.0'
end

execute 'chown_opt' do
  command 'chown root:root /opt'
end

