#############################################################################
# Cookbook Name:: base_config
# Recipe:: default
#
# Copyright 2017, Pentaho, A Hitachi Group Company
#
# All rights reserved - Do Not Redistribute
#############################################################################

# Download and install EPEL-Release 6.8
if `rpm -qa |grep epel-release-6.8`.empty?
  remote_file '/tmp/epel-release-6.8.noarch.rpm' do
    source 'http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  rpm_package 'epel-release-6.8.noarch' do
    source '/tmp/epel-release-6.8.noarch.rpm'
    action :install
  end
end

# Install needed packages
package ['clustershell', 'ntp']

#template '/etc/clustershell/groups.d/local.cfg' do
#  source 'clustershell_groups.erb'
#  owner 'root'
#  group 'root'
#  mode '0644'
#end

# Install openssl to all nodes in the cluster
execute 'openssl_install' do
  command 'clush -ab "yum -y install openssl"'
  not_if 'rpm -qa |grep openssl'
end

# Install Java JDK 1.8.0 for HDP UI
remote_file '/tmp/jdk-8u60-linux-x64.tar.gz' do
  source 'http://resource.pentahoqa.com/engops/java/jdk-8u60-linux-x64.tar.gz'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

execute 'untar_jdk' do
  command 'tar xvzf /tmp/jdk-8u60-linux-x64.tar.gz'
  not_if { ::Dir.exist?('/opt/jdk1.8.0_60') }
end

execute 'java_setup' do
  command ( 'alternatives --install /usr/bin/java java /opt/jdk1.8.0_60/bin/java 2' && 'alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_60/bin/jar 2' && 'alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_60/bin/javac 2' && 'alternatives --set jar /opt/jdk1.8.0_60/bin/jar' && 'alternatives --set javac /opt/jdk1.8.0_60/bin/javac'
  )
  not_if {'alternatives --display java |grep "link currently points to /opt/jdk1.8.0_60/bin/java"'}
end

execute 'kernel_settings' do
  command ( 'echo "fs.file-max = 32768" >> /etc/sysctl.conf' && 'ulimit -n 32768'
  )
  not_if 'cat /etc/sysctl.conf |grep "fs.file-max = 32768"'
end

execute 'limits_settings' do
  command ( 'echo "* - nofile 32768" >> /etc/security/limits.conf' && 'echo "* - noproc 65536" >> /etc/security/limits.conf'
  )
  not_if 'cat /etc/security/limits.conf |egrep "nofile\ 32768|noproc\ 65536"'
end

template '/etc/ntp.conf' do
  source 'ntp.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[ntpd]'
end

service 'ntpd' do
  supports :status => true, :start => true, :stop => true, :restart => true
  action [ :enable, :start]
end

remote_file '/etc/yum.repos.d/ambari.repo' do
  source 'http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.2.1.0/ambari.repo'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  not_if { ::File.exist?('/etc/yum.repos.d/ambari.repo') }
end

remote_file '/etc/yum.repos.d/hdp.repo' do
  source 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.4.0.0/hdp.repo'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  not_if { ::File.exist?('/etc/yum.repos.d/hdp.repo') }
end

template '/etc/init.d/disable-transparent-hugepages' do
  source 'disable-transparent-hugepages.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

# Install disable-tranparent-hugepages script to all nodes in the cluster
execute 'copy_disable_transparent_hugepages' do
  command ( 'clush -ab "--copy /etc/init.d/disable-transparent-hugepages"' && 'clush -ab "chkconfig --add disable-transparent-hugepages"' && 'clush -ab reboot'
  )
  only_if { 'clush -ab ls /etc/init.d/disable-transparent-hugepages |grep "exited with exit code"' }
end

#reboot 'now' do
#  action :nothing
#  reason 'Need to reboot when disable-transparent-hugepages init.d file is created.'
#  delay_mins 1
#end

#execute 'run_reboot' do
#  command 'clush -ab reboot'
#  notifies :reboot_now, 'reboot[now]', :immediately
#  not_if { ::File.exist?('/etc/init.d/disable-transparent-hugepages') }
#end
