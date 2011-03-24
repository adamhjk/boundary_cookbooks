#
# Author:: Joe Williams (<j@fastip.com>)
# Cookbook Name:: erlang
# Attributes:: default
#
# Copyright 2011, fast_ip
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

default[:erlang][:gui_tools] = false

set[:erlang][:epmd][:user] = "epmd"
set[:erlang][:epmd][:uid] = 450
set[:erlang][:epmd][:gid] = 450
set[:erlang][:epmd][:home] = "/home/epmd"
set[:erlang][:epmd][:install_path] = "/usr/local/bin/epmd"

set[:erlang][:erl_call][:install_path] = "/usr/local/bin/erl_call"