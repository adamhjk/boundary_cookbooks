#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: apps
# Definition:: ruby_app
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

define :ruby_app, :name => nil, :app_options => nil do

  include_recipe "git"
  include_recipe "runit"
  
  deploy_config = data_bag_item("apps", params[:name])
  
  if deploy_config["type"] == "ruby"
  
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
      
      if deploy_config["dependencies"]["gems"]
        deploy_config["dependencies"]["gems"].each do |dep, version|
          if version == "latest"
            gem_package dep
          else
            gem_package dep do
              action :install
              version version
            end
          end
        end
      end
    end
    
    #
    # setup config dir
    #
    
    directory "#{deploy_config["install"]["path"]}/etc" do
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode    0755
      recursive true
    end
    
    bash "#{deploy_config["install"]["path"]} permissions" do
      user "root"
      cwd "/opt"
      code <<-EOH
      (chown -R #{deploy_config["system"]["user"]}:#{deploy_config["system"]["group"]} #{deploy_config["install"]["path"]})
      EOH
    end

    #
    # runit service
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
    # setup bin dir and app bin script
    #
       
    directory "#{deploy_config["install"]["path"]}/bin" do
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode    0755
    end
    
    template "#{deploy_config["install"]["path"]}/bin/#{deploy_config["id"]}" do
      source  "ruby/#{deploy_config["id"]}/#{deploy_config["id"]}.erb"
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode    0755
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :restart, resources(:service => "#{deploy_config["id"]}")
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
    # setup log dir
    #
    
    directory "/var/log/#{deploy_config["id"]}" do
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode    0755
    end
    
    #
    # main config file
    #
    
    template "#{deploy_config["install"]["path"]}/etc/#{deploy_config["id"]}.yml" do
      source  "ruby/#{deploy_config["id"]}/config.yml.erb"
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode    0644
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :restart, resources(:service => "#{deploy_config["id"]}")
    end
    
    #
    # for any configs listed in the databag
    #
    
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
    # ssh and git keys
    #

    template "#{deploy_config["install"]["path"]}/etc/git_ssh.sh" do
      source  "ruby/git_ssh.sh.erb"
      owner   deploy_config["system"]["user"]
      group   deploy_config["system"]["group"]
      mode    0755
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
    end
    
    %w[ gitconfig deploy_dsa deploy_dsa.pub ].each do |filename|
      template "#{deploy_config["install"]["path"]}/etc/#{filename}" do
        source  "ruby/#{filename}.erb"
        owner   deploy_config["system"]["user"]
        group   deploy_config["system"]["group"]
        mode    0600
        variables :deploy_config => deploy_config, :app_options => params[:app_options]
      end
    end
        
    #
    # git deploy
    #
    
    git "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}" do
      repository  deploy_config["config"]["git"]["repository"]
      reference   deploy_config["config"]["git"]["reference"]
      action      :sync
      ssh_wrapper "#{deploy_config["install"]["path"]}/etc/git_ssh.sh"
      notifies(:restart, resources(:service => deploy_config["id"]))
    end
    
    #
    # bundle_install if needed
    #
    
    if deploy_config["config"]["bundler"]
      execute "bundle_install" do
        cwd "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}"
        command "bundle install --deployment --without=test:development"
      end
    end
    
    #
    # unicorn setup if needed
    #
    
    if deploy_config["config"]["unicorn"]
      template "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}/unicorn.rb" do
        source "ruby/#{deploy_config["id"]}/unicorn.rb.erb"
        owner   deploy_config["system"]["user"]
        group   deploy_config["system"]["group"]
        mode 0644
        variables :deploy_config => deploy_config, :app_options => params[:app_options]
        notifies :restart, resources(:service => "#{deploy_config["id"]}")
      end

      directory "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}/pids" do
        owner   deploy_config["system"]["user"]
        group   deploy_config["system"]["group"]
        mode 0755
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
    log "#{params[:name]} app is not of type ruby, not deploying"
  end
  
end