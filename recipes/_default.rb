############################################################################
# Cookbook Name:: base_config
# Recipe:: _default
#
# Copyright 2017, Pentaho, A Hitachi Group Company
#
# All rights reserved - Do Not Redistribute
#############################################################################
Chef::Log.info clusterhost = node['hostname']
Chef::Log.info clusterhost[0...-1]
Chef::Log.info (node['hostname'][0...-1] + "1")
Chef::Log.info node1 = (node['hostname'][0...-1] + "1")

user 'devuser' do
  comment 'Hadoop User'
  uid '502'.to_i
  gid '503'.to_i
  home '/home/devuser'
  shell '/bin/bash'
  password '$6$vawoNwBo$ybTw4BFmg9MCgiMjVYWNq4yvVg6hFMzuJ.cysAK8/YerfgB/LvzjFuB.duxP7y7XaD//I8ygOPWH.vFsqBhtm/'
  action :create
end

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

# Install additional needed packages
%w(clustershell ntp openssl python).each do |pkg|
  yum_package pkg

  template '/etc/clustershell/groups.d/local.cfg' do
    source 'clustershell_groups.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end
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

if `ls /home/devuser |grep ShimTestDataLoad3`.empty?
  remote_file '/home/devuser/ShimTestDataLoad3.zip' do
    source 'http://10.177.176.213/engops/ShimTestDataLoad3.zip'
    owner 'devuser'
    group 'devuser'
    mode '0755'
    action :create
  end

  execute 'unzip_ShimTestDataLoad3' do
    command 'unzip /home/devuser/ShimTestDataLoad3.zip -d /home/devuser'
    not_if { ::Dir.exist?('/home/devuser/ShimTestDataLoad3') }
  end
end

# Install Java JDK 1.8.0 into /usr/java directory
directory '/usr/java' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

if `ls /usr/java |grep jdk1.8.0_60`.empty?
  remote_file '/tmp/jdk-8u60-linux-x64.tar.gz' do
    source 'http://resource.pentahoqa.com/engops/java/jdk-8u60-linux-x64.tar.gz'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  execute 'untar_jdk' do
    command 'tar xvzf /tmp/jdk-8u60-linux-x64.tar.gz -C /opt'
    not_if { ::Dir.exist?('/opt/jdk1.8.0_60') }
    notifies :run, 'execute[chown_jdk]', :immediately
  end
end

execute 'chown_jdk' do
  command 'chown -R root:root /opt/jdk1.8.0_60'
  user 'root'
  action :nothing
end

if `alternatives --display java |grep "link currently points to /opt/jdk1.8.0_60/bin/java"`.empty?
  execute 'java_setup' do
    command ( 'alternatives --install /usr/bin/java java /opt/jdk1.8.0_60/bin/java 2' && 'alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_60/bin/jar 2' && 'alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_60/bin/javac 2' && 'alternatives --set jar /opt/jdk1.8.0_60/bin/jar' && 'alternatives --set javac /opt/jdk1.8.0_60/bin/javac'
    )
  end
end

execute 'kernel_settings' do
  command ( 'echo "fs.file-max = 32768" >> /etc/sysctl.conf' && 'ulimit -n 32768'
  )
  not_if 'cat /etc/sysctl.conf |grep "fs.file-max = 32768"'
end

if `cat /etc/security/limits.conf |egrep "nofile\ 32768|noproc\ 65536"`.empty?
  execute 'limits_settings' do
    command ( 'echo "* - nofile 32768" >> /etc/security/limits.conf' && 'echo "* - noproc 65536" >> /etc/security/limits.conf'
    )
  end
end

template '/etc/init.d/disable-transparent-hugepages' do
  source 'disable-transparent-hugepages.erb'
  owner 'root'
  group 'root'
  mode '0755'
end
