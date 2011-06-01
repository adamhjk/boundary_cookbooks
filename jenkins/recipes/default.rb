#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: jenkins
# Recipe:: default
#
# Copyright 2011, Boundary
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


bash "install jenkins" do
  cwd "/tmp"
  code <<-EOH
  wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
  echo "deb http://pkg.jenkins-ci.org/debian binary/" > /etc/apt/sources.list.d/jenkins.list
  apt-get update
  apt-get install jenkins
  EOH
  not_if "/usr/bin/test -d /var/lib/jenkins"
end

service "jenkins" do
  supports :status => true, :restart => true
  action [ :start, :enable ]
end

cookbook_file "/var/lib/jenkins/.gitconfig" do
  source "gitconfig"
  owner "jenkins"
  group "nogroup"
end