#
# Cookbook Name:: tomcat6
# Recipe:: default
#
# Copyright 2012, FOX Sports 2Go - Operations
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# put archive with tomcat
include_recipe "tomcat6archive"

cookbook_file "/opt/apr.tar" do
    source "apr.tar"
    mode 0444
    owner "root"
    group "root"
    action :create_if_missing
end

# create group tomcat

group "tomcat" do
  gid 91
end

user "tomcat" do
  comment "tomcat service user"
  system true
  home "/opt/tomcat"
  uid 91
  gid 91
end


bash "tomcat" do
  user "root"
  cwd "/tmp"
  code <<-EOH
if [ -L /opt/tomcat ]
    then
        /bin/echo "Tomcat are installed."
        directory="/mnt/ephemeral"
	if [ -d $directory ]
	    then
    		if [ ! -L /opt/tomcat/logs ]
    		    then
    			echo "Moving logs to ephemeral."
        		/sbin/service tomcat stop
        		mkdir $directory/tomcatLogs
		        chown tomcat.tomcat $directory/tomcatLogs
	    		rm -rf /opt/tomcat/logs
		        ln -s $directory/tomcatLogs /opt/tomcat/logs
		        sleep 10
		        /sbin/service tomcat start
		fi
	fi
    else
        /bin/echo "Installing tomcat..."
        /bin/tar xvf /opt/apache-tomcat-6.0.35.tar.gz -C /opt
        /bin/chown -R tomcat.tomcat /opt/apache-tomcat-6.0.35
        /bin/ln -s /opt/apache-tomcat-6.0.35 /opt/tomcat
	# move logs to ephemeral
	directory="/mnt/ephemeral"
	if [ -d $directory ]
	    then
    		mkdir $directory/tomcatLogs
	        chown tomcat.tomcat $directory/tomcatLogs
	        rm -rf /opt/tomcat/logs
	        ln -s $directory/tomcatLogs /opt/tomcat/logs
	fi
	# install apr
	/bin/tar xvf /opt/apr.tar -C /opt/tomcat/lib
        /bin/echo "done."
fi

EOH
end

# fix limits for tomcat user

cookbook_file "/etc/security/limits.conf" do
    source "limits.conf"
    mode 0644
    owner "root"
    group "root"
end

cookbook_file "/etc/init.d/tomcat" do
    source "tomcat"
    mode 0755
    owner "root"
    group "root"
    action :create_if_missing
end

cookbook_file "/etc/profile.d/tomcat.sh" do
    source "tomcat.sh"
    mode 0644
    owner "root"
    group "root"
    action :create_if_missing
end


service "tomcat" do
  supports :stop => true, :restart => true, :start => true
  action [ :enable, :start ]
end

