#
# Cookbook Name:: wordpress
# Recipe:: default
#
# Copyright 2009-2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or impl`ied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'mysql::server'
include_recipe 'php::module_mysql'
include_recipe 'php'

if 'apache2'.eql?(node['wordpress']['webserver']) || :apache2.eql?(node['wordpress']['webserver'])
  include_recipe 'apache2'
  include_recipe 'apache2::mod_php5'
elsif 'nginx'.eql?(node['wordpress']['webserver']) || :nginx.eql?(node['wordpress']['webserver'])
  include_recipe 'nginx'
  include_recipe 'php-fpm'
else
  raise "Unknown wordpress webserver #{node['wordpress']['webserver']}."
end
