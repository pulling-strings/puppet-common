# common/manifests/defines/concatenated_file.pp -- create a file from snippets
# stored in a directory
#
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

# TODO:
# * create the directory in _part too
#
# This resource collects file snippets from a directory ($dir) and concatenates
# them in lexical order of their names into a new file ($name). This can be
# used to collect information from disparate sources, when the target file
# format doesn't allow includes.
#
# concatenated_file_part can be used to easily configure content for this.
#
# If no $dir is specified, the target name with '.d' appended will be used.
#
# The $dir is purged by puppet and will only contain explicitely configured
# files. This can be overridden by defining the directory before the
# concatenated_file.
#
# Depend on File[$name] to change if and only if its contents change. Notify
# Exec["concat_${name}"] if you want to force an update.
#
# Parameters:
#
# - *$dir: where the snippets are located
# - *$header: a file with content to prepend
# - *$footer: a file with content to append
# - $mode = 0644, $owner = root, $group = 0: default permissions for the target file
# Usage:
# concatenated_file { "/etc/some.conf":
# 	dir => "/etc/some.conf.d"
# }
#
# Use Exec["concat_$name"] as Semaphor
#
define common::concatenated::file ($ensure = 'present',
																	 $dir    = '',
																	 $header = '',
																	 $footer = '',
																	 $mode   = '0644',
																	 $owner  = 'root',
																	 $group  = 'root') {

	include common::moduledir::common::cf
	
	$dir_real = $dir ? {
		''      => "${name}.d",
		default => $dir,
	}
	
	$tmp_file_name = regsubst($dir_real, '/', '_', 'G')
	$tmp_file = "${common::moduledir::module_dir_path}/${tmp_file_name}"

	if defined(File[$dir_real]) {
		debug("${dir_real} already defined")
	} else {
		file { $dir_real:
				ensure => $ensure ? {
					'present' => directory,
					default   => $ensure
				},
				source   => 'puppet:///modules/common/empty',
				checksum => mtime,
				ignore   => '.ignore',
				recurse  => true,
				purge    => true,
				force    => true,
				mode     => $mode,
				owner    => $owner,
				group    => $group,
				notify   => Exec["concat_${name}"],
		}
	}

	file { $tmp_file:
			ensure   => $ensure,
			checksum => md5,
			owner    => $owner,
			group    => $group,
			mode     => $mode,
	}
	
	# decouple the actual file from the generation process by using a
	# temporary file and puppet's source mechanism. This ensures that events
	# for notify/subscribe will only be generated when there is an actual
	# change.
	file { $name:
		ensure   => $ensure,
		checksum => md5,
		source   => $tmp_file,
		owner    => $owner,
		group    => $group,
		mode     => $mode,
		require  => File[$tmp_file],
	}

	if $ensure == 'present' {
		# if there is a header or footer file, add it
		$additional_cmd = $header ? {
			''      => $footer ? {
				''      => '',
				default => "| cat - '${footer}' ",
			},
			default => $footer ? { 
				''      => "| cat '${header}' - ",
				default => "| cat '${header}' - '${footer}' ",
			}
		}
	
		# use >| to force clobbering the target file
		exec { "concat_${name}":
			command     => "/usr/bin/find ${dir_real} -maxdepth 1 -type f ! -name '*puppettmp' -print0 | sort -z | xargs -0 cat ${additional_cmd} >| ${tmp_file}",
			refreshonly => true,
			subscribe   => File[$dir_real],
			before      => File[$tmp_file],
			alias       => "concat_${dir_real}",
			loglevel    => info,
		}
	}
}
