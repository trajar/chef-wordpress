
default['wordpress']['url'] = 'http://wordpress.org/latest.tar.gz'
default['wordpress']['db']['password'] = nil
default['wordpress']['db']['character_set'] = 'utf8'
default['wordpress']['server_aliases'] = [node['fqdn']]
default['wordpress']['webserver'] = 'apache2'
