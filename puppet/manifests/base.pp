# Set paths to use in exec commands
Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin' }
Class['apt'] -> Package<| |>
Anchor['apt::source::php55'] -> Class['php'] -> Class['composer']

# Dependencies
package{'vim':
	ensure => 'present'
}
package {'libevent-dev':
	ensure => installed,
	before => Class['php']
}
package {'libev-dev':
	ensure => installed,
	before => Class['php']
}
package {'pkg-config':
	ensure => installed,
	before => Class['php']
}
package {'libzmq-dev':
	ensure => installed,
	before => Class['php']
}
package {'build-essential':
	ensure => installed,
	before => Class['php']
}
package {"curl":
	ensure => installed,
	before => Class['php']
}
package {"git-core":
	ensure => installed,
	before => Class['php']
}

# Add the APT module
class{'apt':
	always_apt_update => true
}
apt::source{'php55':
	location   => 'http://packages.dotdeb.org',
	release    => 'wheezy-php55',
	repos      => 'all',
	key        => 'E9C74FEEA2098A6E',
	key_server => 'keys.gnupg.net'
}

# Apache config
class{'apache':
	mpm_module    => 'prefork'
}

class{'apache::mod::php':}
class{'apache::mod::rewrite':}
apache::vhost{ 'example.dev':
	port    => '80',
	docroot => '/vagrant/web'
}

# Mysql server
include '::mysql::server'

# PHP config
include 'php'

php::module{'mysql':}
php::module { "apcu":
	module_prefix => "php5-"
}
php::module { "imagick": }
php::module { "gd": }
php::module { "mcrypt": }
php::module { "memcache": }
php::module { "pspell": }
php::module { "snmp": }
php::module { "sqlite": }
php::module { "xmlrpc": }
php::module { "xsl": }
php::module { "curl": }
php::pecl::module { "xdebug": }
php::pecl::module { "libevent":
	preferred_state => "beta",
	use_package     => 'false'
}
php::pecl::module { 'zmq':
	preferred_state => "beta",
	use_package     => 'false'
}
exec { 'git clone --recursive https://github.com/m4rw3r/php-libev && cd php-libev && phpize && ./configure --with-libev && make && make install':
	cwd     => '/tmp',
	require => [Package['git-core'], Package['php5-dev'], Package['libev-dev']],
	alias   => 'git-libev'
}

# Setting a default timezone avoids warning about date default timezone
php::augeas{
	'php-date_timezone_apache':
		entry   => 'Date/date.timezone',
		value   => 'UTC',
		notify  => Service['apache2'],
		require => Class['php'];
	'php-date_timezone_cli':
		entry   => 'Date/date.timezone',
		value   => 'UTC',
		require => Class['php'],
		target  => '/etc/php5/cli/php.ini',
}

# Composer config
class{'composer':
	target_dir      => '/usr/local/bin',
	composer_file   => 'composer',
	suhosin_enabled => false
}

# Config files for custom compiled PECL modules
file {'/etc/php5/cli/libevent.ini':
	path    => '/etc/php5/cli/conf.d/libevent.ini',
	content => 'extension=libevent.so',
	require => Exec['pecl-libevent'],
}
file {'/etc/php5/cli/zmq.ini':
	path    => '/etc/php5/cli/conf.d/zmq.ini',
	content => 'extension=zmq.so',
	require => Exec['pecl-zmq'],
}
file {'/etc/php5/apache2/libevent.ini':
	path    => '/etc/php5/apache2/conf.d/libevent.ini',
	content => 'extension=libevent.so',
	require => Exec['pecl-libevent'],
	notify  => Service['apache2'],
}
file {'/etc/php5/apache2/zmq.ini':
	path    => '/etc/php5/apache2/conf.d/zmq.ini',
	content => 'extension=zmq.so',
	require => Exec['pecl-zmq'],
	notify  => Service['apache2'],
}
file {'/etc/php5/cli/libev.ini':
	path    => '/etc/php5/cli/conf.d/libev.ini',
	content => 'extension=libev.so',
	require => Exec['git-libev'],
}
file {'/etc/php5/apache2/libev.ini':
	path    => '/etc/php5/apache2/conf.d/libev.ini',
	content => 'extension=libev.so',
	require => Exec['git-libev'],
	notify  => Service['apache2']
}
