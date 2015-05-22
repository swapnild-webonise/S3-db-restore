#
# Cookbook Name:: backup
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#package "apti" 

if platform_family?("rhel")
  s3cmd_binary = "/usr/bin/s3cmd"
else
  s3cmd_binary = "/usr/local/bin/s3cmd"
end

#######  Install Dependencies  ###############
package "python-setuptools" do
    action :install
  end
##############################################

#execute "touch" do
#	command "touch /tmp/abc"
#not_if { ::File.exists?(s3cmd_binary) }
#end

######  Download and install s3cmd  ####################
if  !(::File.exists?(s3cmd_binary))
remote_file "/tmp/s3cmd-1.5.2.tar.gz" do
	source "http://liquidtelecom.dl.sourceforge.net/project/s3tools/s3cmd/1.5.2/s3cmd-1.5.2.tar.gz"
  	not_if { ::File.exists?('/tmp/s3cmd-1.5.2.tar.gz') }
	end


	execute "extract and install tar" do
	  cwd '/tmp'
	  command <<-EOF
	  tar xvzf s3cmd-1.5.2.tar.gz
	  cd /tmp/s3cmd-1.5.2/
	  python setup.py install
	  EOF
	  end
end	#end if
##########################################################

####################  Get data from s3  ##################
ENV['AWS_ACCESS_KEY'] = node['aws']['access_key']
ENV['AWS_SECRET_KEY'] = node['aws']['secret_key']


directory node["temp_dir"] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

execute "test" do
	command <<-EOF
	db_url=`s3cmd ls #{node['s3']['bucket_path']} | sort -r -k 4 | head -1 | awk '{print $4}'`
	s3cmd ls #{node['s3']['bucket_path']} >> /tmp/s3
	s3cmd get $db_url #{node['temp_dir']}
	db=`ls -r #{node['temp_dir']} | head -1`
	gunzip #{node['temp_dir']}/$db
        db=`ls -r #{node['temp_dir']} | head -1`

	sudo -u postgres bash <<-EOH
		dropdb #{node['db_name']}
		createdb #{node['db_name']}
		psql #{node['db_name']} < #{node['temp_dir']}/$db
	EOH
	
	EOF

end

