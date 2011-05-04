#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: apps
# Definition:: jvm_app
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

define :jvm_app, :name => nil, :app_options => nil do
  
  include_recipe "runit"
  include_recipe "java"
  
  deploy_config = data_bag_item("apps", params[:name])

  if deploy_config["type"] == "jvm"
  
    #
    # user and group
    #
    
    group deploy_config["system"]["group"] do
      gid deploy_config["system"]["gid"]
    end
    
    user deploy_config["system"]["user"] do
      uid deploy_config["system"]["uid"]
      gid deploy_config["system"]["gid"]
      home deploy_config["system"]["home"]
      shell "/bin/bash"
      system true
    end
    
    directory deploy_config["system"]["home"] do
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode    0700
    end
    
    #
    # install dependencies
    #

    if deploy_config["dependencies"]
      if deploy_config["dependencies"]["recipes"]
        deploy_config["dependencies"]["recipes"].each do |dep|
          include_recipe dep
        end
      end
      
      if deploy_config["dependencies"]["system"]
        deploy_config["dependencies"]["system"].each do |dep|
          package dep
        end
      end
    end
    
    #
    # setup runit service
    #
    
    runit_service "#{deploy_config["id"]}" do
      template_name "app"
      options deploy_config
    end
    
    service "#{deploy_config["id"]}" do
      supports :status => true, :restart => true
      action [ :start ]
    end
    
    #
    # base install
    #
    
    %w[ lib etc bin ].each do |dir|
      directory "#{deploy_config["install"]["path"]}/#{dir}" do
        owner deploy_config["system"]["user"]
        group deploy_config["system"]["group"]
        recursive true
      end
    end
    
    local_filename = "#{deploy_config["id"]}.jar"
    remote_filename = "#{deploy_config["id"]}_#{deploy_config["version"]}.jar"
    
    remote_file "#{deploy_config["install"]["path"]}/lib/#{local_filename}" do
      source "#{deploy_config["install"]["repo_url"]}/#{deploy_config["id"]}/#{remote_filename}"
      backup false
      checksum deploy_config["checksum"]
      not_if "/usr/bin/test -d #{deploy_config["install"]["path"]}/lib/#{local_filename}"
      notifies :restart, resources(:service => "#{deploy_config["id"]}")
    end
    
    bash "#{deploy_config["install"]["path"]} permissions" do
      user "root"
      cwd "/opt"
      code <<-EOH
      (chown -R #{deploy_config["system"]["user"]}:#{deploy_config["system"]["group"]} #{deploy_config["install"]["path"]})
      EOH
    end
    
    #
    # setup log dir
    #
    
    directory "/var/log/#{deploy_config["id"]}" do
      owner deploy_config["system"]["user"]
      group deploy_config["system"]["group"]
    end
    
    #
    # setup additional directories
    #
    
    if deploy_config["config"]["additional_directories"]
      deploy_config["config"]["additional_directories"].each do |dir|
        directory dir do
          owner   deploy_config["system"]["user"]
          group   deploy_config["system"]["group"]
          mode    0755
          recursive true
        end
      end
    end
    
    #
    # general config
    #
        
    # the start script
    template "#{deploy_config["install"]["path"]}/bin/#{deploy_config["id"]}" do
      source "jvm/#{deploy_config["id"]}/#{deploy_config["id"]}.erb"
      owner deploy_config["system"]["user"]
      group deploy_config["system"]["group"]
      mode 0755
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :restart, resources(:service => "#{deploy_config["id"]}")
    end
    
    # default log4j
    template "#{deploy_config["install"]["path"]}/etc/log4j.properties" do
      source "jvm/log4j.properties.erb"
      owner deploy_config["system"]["user"]
      group deploy_config["system"]["group"]
      mode 0644
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :restart, resources(:service => "#{deploy_config["id"]}")
    end
    
    # other configs listed in the databag
    if deploy_config["config"]["additional_config_templates"]
      deploy_config["config"]["additional_config_templates"].each do |config|
        template "#{deploy_config["install"]["path"]}/etc/#{config}" do
          source "#{deploy_config["type"]}/#{deploy_config["id"]}/#{config}.erb"
          owner deploy_config["system"]["user"]
          group deploy_config["system"]["group"]
          mode 0644
          variables :deploy_config => deploy_config, :app_options => params[:app_options]
          notifies :restart, resources(:service => "#{deploy_config["id"]}")
        end
      end
    end
    
    # other bins listed in the databag
    if deploy_config["config"]["additional_bin_templates"]
      deploy_config["config"]["additional_bin_templates"].each do |config|
        template "#{deploy_config["install"]["path"]}/bin/#{config}" do
          source "#{deploy_config["type"]}/#{deploy_config["id"]}/#{config}.erb"
          owner deploy_config["system"]["user"]
          group deploy_config["system"]["group"]
          mode 0755
          variables :deploy_config => deploy_config, :app_options => params[:app_options]
        end
      end
    end
    
    #
    # iptables if needed
    #
    
    if deploy_config["config"]["iptables"]
      iptables_rule "10#{deploy_config["id"]}" do
        source "#{deploy_config["type"]}/#{deploy_config["id"]}/iptables_rules.erb"
      end
    end
    
  else
    log "#{params[:name]} app is not of type jvm, not deploying"
  end
  
end