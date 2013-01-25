Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin' }
exec { "apt-update":
    command => "/usr/bin/apt-get update"
}

Exec["apt-update"] -> Package <| |>	
class { 'composer':
	command_name => 'composer',
	target_dir   => '/usr/local/bin',
	auto_update  => true,
	require      => Class['php_modules']
}
exec { 'composer install':
	cwd     => '/vagrant',
	require => Class['composer']
}

include repository
include dependencies
include apache
include mysql
include php
include php::devel
include php::pear
include php_modules
include webserver