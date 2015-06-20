
include Opscode::OpenSSL::Password

action :create do

  site_dir = @new_resource.site_dir
  site_name = @new_resource.site_name
  if site_name.nil? && site_dir.nil?
    raise 'Must specify either wordpress installation directory or site name.'
  end
  if site_name.nil? && site_dir
    site_name = ::File.basename(site_dir)
  end
  if site_dir.nil? && site_name
    site_dir = "/var/www/#{site_name}"
  end

  server_aliases = @new_resource.server_aliases || node['wordpress']['server_aliases']
  database = @new_resource.database || site_name
  db_user = @new_resource.db_user || node['wordpress']['db']['user']
  db_password = @new_resource.db_password || node['wordpress']['db']['password'] || secure_password
  db_character_set = @new_resource.db_character_set || node['wordpress']['db']['character_set']

  if node.has_key?('ec2')
    server_fqdn = node['ec2']['public_hostname']
  else
    server_fqdn = node['fqdn']
  end

  keys_auth = secure_password
  keys_secure_auth = secure_password
  keys_logged_in = secure_password
  keys_nonce = secure_password

  tarball = "#{Chef::Config[:file_cache_path]}/wordpress-#{site_name}.tar.gz"
  grants = "#{node['mysql']['conf_dir']}/#{database}-grants.sql"

  remote_file "#{tarball}" do
    checksum node['wordpress']['checksum']
    source node['wordpress']['url']
    mode '0644'
  end

  execute "#{site_dir}-mkdir" do
    command "mkdir -p #{site_dir}"
    creates "#{site_dir}"
  end

  execute "#{site_dir}-untar" do
    cwd site_dir
    command "tar --strip-components 1 -xzf #{tarball}"
    creates "#{site_dir}/wp-settings.php"
  end

  execute "#{database}-privileges" do
    command "/usr/bin/mysql -u root -p\"#{node['mysql']['server_root_password']}\" < #{grants}"
    action :nothing
  end

  template "#{grants}" do
    source 'grants.sql.erb'
    cookbook 'wordpress'
    owner 'root'
    group 'root'
    mode '0600'
    variables(
      :user     => db_user,
      :password => db_password,
      :database => database
    )
    notifies :run, "execute[#{database}-privileges]", :immediately
  end

  execute "#{database}-create" do
    command "/usr/bin/mysqladmin -u root -p\"#{node['mysql']['server_root_password']}\" create #{database} --default-character-set=#{db_character_set}"
    not_if do
      require 'mysql'
      m = Mysql.new('localhost', 'root', node['mysql']['server_root_password'])
      m.list_dbs.include?(database)
    end
    notifies :create, 'ruby_block[save node data]', :immediately unless Chef::Config[:solo]
  end

  unless Chef::Config[:solo]
    ruby_block 'save node data' do
      block do
        node.save
      end
      action :create
    end
  end

  template "#{site_dir}/wp-config.php" do
    source 'wp-config.php.erb'
    cookbook 'wordpress'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      :database        => database,
      :user            => db_user,
      :password        => db_password,
      :character_set   => db_character_set,
      :auth_key        => keys_auth,
      :secure_auth_key => keys_secure_auth,
      :logged_in_key   => keys_logged_in,
      :nonce_key       => keys_nonce
    )
  end

  if 'apache2'.eql?(node['wordpress']['webserver']) || :apache2.eql?(node['wordpress']['webserver'])

    apache_site 'default' do
      enable false
    end

    web_app "#{site_name}" do
      template 'wordpress-apache2.conf.erb'
      cookbook 'wordpress'
      docroot site_dir
      site_name site_name
      server_name server_fqdn
      server_aliases server_aliases
    end

  elsif 'nginx'.eql?(node['wordpress']['webserver']) || :nginx.eql?(node['wordpress']['webserver'])

    template "#{node['nginx']['dir']}/wordpress.conf" do
      source 'wordpress-nginx-common.conf.erb'
      cookbook 'wordpress'
      owner 'root'
      group 'root'
      mode '0644'
      variables({
        :php_fpm_socket => node['wordpress']['php_fpm']['listen']
      })
    end

    template "#{node['nginx']['dir']}/sites-available/#{site_name}" do
      source 'wordpress-nginx.conf.erb'
      cookbook 'wordpress'
      owner 'root'
      group 'root'
      mode '0644'
      variables({
        :docroot => site_dir,
        :server_aliases => server_aliases,
        :log_dir => node['nginx']['log_dir'],
        :log_name => site_name
      })
    end

    nginx_site "#{site_name}" do
      action :enable
    end

  end

end