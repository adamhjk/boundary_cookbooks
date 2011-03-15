# install erl_call

cookbook_file node[:erlang][:erl_call][:install_path] do
  source "erl_call.#{node[:kernel][:machine]}"
  owner "root"
  mode 0755
end