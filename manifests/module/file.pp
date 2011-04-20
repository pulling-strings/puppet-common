# common/manifests/defines/modules_file.pp -- use a modules_dir to store module
# specific files
#
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.
# Usage:
# common::module::file { "module/file":
#		source => "puppet://${server}/...",
#		mode   => 644,   # default
#   owner  => root,  # default
#   group  => root     # default
#	}
define module_file ($source, $ensure = present, $alias = undef, $mode = 0644,
										$owner = root, $group = root) {
	include common::moduledir

	file { "${common::moduledir::module_dir_path}/${name}":
		ensure => $ensure,
		alias  => $alias,
		source => $source,
		owner  => $owner,
		group  => $group,
		mode   => $mode
	}
}
