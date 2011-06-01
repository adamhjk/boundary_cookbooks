#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: jenkins
# Provider:: default
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

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :create_job do
  create_job(new_resource)
end

action :delete_job do
  delete_job(new_resource)
end

action :install_plugin do
  install_plugin(new_resource)
end

action :reload_configuration do
  reload_configuration(new_resource)
end

private


def create_job(new_resource)
  if job_exists?(new_resource)
    Chef::Log.debug("Jenkins job [#{new_resource.name}] already exists, not creating")
  else
    # write empty config to disk
    setup_empty_config("/tmp/.jenkins_empty_config")
    
    # create basic job
    base_command = build_base_command(new_resource)
    command = "cat /tmp/.jenkins_empty_config | #{base_command} create-job #{new_resource.name}"
    Chef::Log.debug("Creating Jenkins job with:\n#{command}")
    run_command(command)
    Chef::Log.info("Created Jenkins job [#{new_resource.name}]")
  end
end

def delete_job(new_resource)
  if job_exists?(new_resource)
    # delete job
    base_command = build_base_command(new_resource)
    command = "#{base_command} delete-job #{new_resource.name}"
    run_command(command)
    Chef::Log.info("Deleted Jenkins job [#{new_resource.name}]")
  else
    Chef::Log.debug("Jenkins job [#{new_resource.name}] does not exist, not deleting")
  end
end

def install_plugin(new_resource)
  if plugin_installed?(new_resource)
    Chef::Log.debug("Jenkins plugin [#{new_resource.name}] already installed, not installing")
  else
    # install a plugin
    base_command = build_base_command(new_resource)
    command = "#{base_command} install-plugin #{new_resource.name}"
    run_command(command)
    Chef::Log.info("Installed Jenkins plugin [#{new_resource.name}]")    
  end
end

def reload_configuration(new_resource)
  # reload configurations from disk
  base_command = build_base_command(new_resource)
  command = "#{base_command} reload-configuration"
  run_command(command)
  Chef::Log.info("Reloaded Jenkins configurations from disk")
end

def setup_empty_config(file)
  empty_config = <<-EOH
<?xml version='1.0' encoding='UTF-8'?>
<project>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <scm class="hudson.scm.NullSCM"/>
  <canRoam>false</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers class="vector"/>
  <concurrentBuild>false</concurrentBuild>
  <builders/>
  <publishers/>
  <buildWrappers/>
</project>
EOH
  
  file file do
    content empty_config
  end
end

def job_exists?(new_resource)
  ::File.exists?("#{new_resource.path}/jobs/#{new_resource.name}/config.xml")
end

def plugin_installed?(new_resource)
  ::File.exists?("#{new_resource.path}/plugins/#{new_resource.name}.hpi")
end

def build_base_command(new_resource)
  "java -jar #{new_resource.cli_jar} -s #{new_resource.url}"
end

def run_command(command)
  output = shell_out!(command)
  Chef::Log.debug("Jenkins command output:\n#{output}")
end