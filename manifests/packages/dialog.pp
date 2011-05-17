# Class: common::packages::dialog
#
#
class common::packages::dialog {
	package { dialog:
		ensure => installed,
	}
}
