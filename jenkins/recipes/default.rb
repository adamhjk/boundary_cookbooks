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

remote_file "/tmp/jenkins-ci.org.key" do
  source "http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key"
  not_if "apt-key list | grep '1024D/D50582E6'
  notifies :run, execute["add jenkins apt key"], :immediately
end

execute "add jenkins apt key" do
  command "apt-key add /tmp/jenkins-ci.org.key"
  action :nothing
  notifies :run, execute["apt-get update for jenkins"], :immediately
end

execute "apt-get update for jenkins" do
  command "apt-get update"
  action :nothing
end

package "jenkins"

service "jenkins" do
  supports :status => true, :restart => true
  action [ :start, :enable ]
end