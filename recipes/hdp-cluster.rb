#############################################################################
# Cookbook Name:: base_config
# Recipe:: hdp-cluster
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

if node['hostname'] == (node['hostname'][0...-1] + "1")
  remote_file '/etc/yum.repos.d/ambari.repo' do
    source 'http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.4.1.0/ambari.repo'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
    not_if { ::File.exist?('/etc/yum.repos.d/ambari.repo') }
  end

  remote_file '/etc/yum.repos.d/hdp.repo' do
    source 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.5.3.0/hdp.repo'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
    not_if { ::File.exist?('/etc/yum.repos.d/hdp.repo') }
  end
end

# if node['hostname'] == (node['hostname'][0...-1] + "1")
#   if `rpm -qa |grep ambari-server`.empty?
#     pkg ambari-server
