
node[:tungsten][:prereqPackages].each do |pkg|
  package pkg do
    action :install
  end
end

execute "setRubyVersion" do
	command "alternatives --set ruby /usr/bin/ruby1.8"
end

if node[:tungsten][:installJava] == true
	package "java" do
		action :install
		not_if { node[:platform] == "amazon" }
	end
	package "java-1.7.0-openjdk" do
		action :install
		only_if { node[:platform] == "amazon" }
	end
end

group node[:tungsten][:systemUser] do
	action :create
	gid 6000
end

user node[:tungsten][:systemUser] do
	action :create
	supports :manage_home => true
	comment "Continuent Tungsten User"
	uid 6000
	gid 6000
	home "/home/#{node[:tungsten][:systemUser]}"
	shell "/bin/bash"
	#password "$1$JJsvHslV$szsCjVEroftprNn4JHtDi."
end

directory "/home/#{node[:tungsten][:systemUser]}" do
  owner node[:tungsten][:systemUser]
  group node[:tungsten][:systemUser]
  mode 00750
  action :create
end

directory "/home/#{node[:tungsten][:systemUser]}/.ssh" do
  only_if { File.directory?("/home/#{node[:tungsten][:systemUser]}") }
  action :create
  owner node[:tungsten][:systemUser]
  group node[:tungsten][:systemUser]
  mode 00700
end

template "/home/#{node[:tungsten][:systemUser]}/.bash_profile" do
  only_if { File.directory?("/home/#{node[:tungsten][:systemUser]}") }
  action :create
  owner node[:tungsten][:systemUser]
  group node[:tungsten][:systemUser]
  mode 00644
  source "tungsten_bash_profile.erb"
end

node[:tungsten][:prereqDirectories].each do |dir|
	directory dir do
	  owner node[:tungsten][:systemUser]
	  group node[:tungsten][:systemUser]
	  mode 00750
	  action :create
	end
end

template "/etc/sudoers.d/90_tungsten" do
	only_if { File.directory?("/etc/sudoers.d") }
	action :create
	mode 00440
	owner "root"
	group "root"
	source "tungsten_sudo.erb"
end

template "/etc/security/limits.d/90tungsten.conf" do
	only_if { File.directory?("/etc/security/limits.d") }
	action :create
	mode 00440
	owner "root"
	group "root"
	source "tungsten_security_limits.erb"
end

execute "remove-requiretty" do
	command "/bin/sed -i '/requiretty/s/^Defaults/#Defaults/' /etc/sudoers"
	only_if "/bin/grep requiretty /etc/sudoers | /bin/egrep -v \"^#\""
end

cookbook_file "mysql-connector-java-5.1.26-bin.jar" do
	path node[:tungsten][:mysqljLocation]
	owner node[:tungsten][:systemUser]
	group node[:tungsten][:systemUser]
	mode 00644
	action :create_if_missing
	only_if { node[:tungsten][:installMysqlj] == true }
end

file "/selinux/enforcing" do
	owner "root"
	mode 00600
	content "0"
	only_if { node[:tungsten][:disableSELinux] == true }
end

if node[:tungsten][:installSSHKeys] == true

	file "/home/#{node[:tungsten][:systemUser]}/.ssh/id_rsa" do
		mode 00600
		owner node[:tungsten][:systemUser]
		content node[:tungsten][:sshPrivateKey]
		only_if { File.directory?("/home/#{node[:tungsten][:systemUser]}/.ssh") }
	end

	file "/home/#{node[:tungsten][:systemUser]}/.ssh/id_rsa.pub" do
		mode 00600
		owner node[:tungsten][:systemUser]
		content "ssh-rsa #{node[:tungsten][:sshPublicKey]}"
		only_if { File.directory?("/home/#{node[:tungsten][:systemUser]}/.ssh") }
	end

	file "/home/#{node[:tungsten][:systemUser]}/.ssh/authorized_keys" do
		mode 00600
		owner node[:tungsten][:systemUser]
		content "ssh-rsa #{node[:tungsten][:sshPublicKey]} #{node[:tungsten][:systemUser]}"
		only_if { File.directory?("/home/#{node[:tungsten][:systemUser]}/.ssh") }
	end

end