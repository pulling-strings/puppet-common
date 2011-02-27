# common/manifests/defines/config_file.pp -- create a config file with default permissions
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

# Usage:
# config_file { filename:
# 	content => "....\n",
# }
#
# Examples: 
#
# To create the file /etc/vservers/${vs_name}/context with specific
# content:
#
# common::config_file { "/etc/vservers/${vs_name}/context":
#              content => "${context}\n",
#              notify => Exec["vs_restart_${vs_name}"],
#              require => Exec["vs_create_${vs_name}"];
# }
#
# To create the file /etc/apache2/sites-available/munin-stats with the
# content pulled from a template:
#
# common::config_file { "/etc/apache2/sites-available/munin-stats":
#              content => template("apache/munin-stats"),
#              require => Package["apache2"],
#              notify => Exec["reload-apache2"]
# }

define common::config_file ($content = '', $source = '', $ensure = 'present') {
	file { $name:
		ensure   => $ensure,
		backup   => server, # keep old versions on the server
		mode     => 0644, # default permissions for config files
		owner    => root,
		group    => 0,
		checksum => md5 # really detect changes to this file
	}

	case $source {
		'': { }
		default: {
			File[$name] {
				source => $source
			}
		}
	}

	case $content {
		'': { }
		default: {
			File[$name] {
				content => $content
			}
		}
	}		
}
