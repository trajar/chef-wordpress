
actions :create

attribute :site_dir,            :kind_of => String, :default => nil
attribute :site_name,           :kind_of => String, :default => nil
attribute :server_aliases,      :kind_of => Array, :default => []
attribute :database,            :kind_of => String, :default => nil
attribute :db_user,             :kind_of => String, :default => nil
attribute :db_password,         :kind_of => String, :default => nil
attribute :db_character_set,    :kind_of => String, :default => 'utf8'
