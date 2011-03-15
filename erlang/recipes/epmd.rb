# install and setup epmd service under runit

group node[:erlang][:epmd][:user] do
  gid node[:erlang][:epmd][:gid]
end

user node[:erlang][:epmd][:user] do
  uid node[:erlang][:epmd][:uid]
  gid node[:erlang][:epmd][:gid]
  home node[:erlang][:epmd][:home]
  shell "/bin/bash"
  system true
end

cookbook_file node[:erlang][:epmd][:install_path] do
  source "epmd.#{node[:kernel][:machine]}"
  mode 0755
  owner "root"
end

hash = {"user" => node[:erlang][:epmd][:user]}

runit_service "epmd" do
  options hash
end