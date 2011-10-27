# 
# == Definition: common::archive::download
# 
# Archive downloader with integrity verification.
# 
# Parameters:
# 
# - *$url: 
# - *$digest_url:
# - *$digest_string: Default value "" 
# - *$digest_type: Default value "md5".
# - *$timeout: Default value 120.
# - *$src_target: Default value "/usr/src".
# 
# Example usage:
# 
#   common::archive::download {"apache-tomcat-6.0.26.tar.gz":
#     ensure => present,
#     url => "http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.26/bin/apache-tomcat-6.0.26.tar.gz",
#   }
#   
#   common::archive::download {"apache-tomcat-6.0.26.tar.gz":
#     ensure => present,
#     digest_string => "f9eafa9bfd620324d1270ae8f09a8c89",
#     url => "http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.26/bin/apache-tomcat-6.0.26.tar.gz",
#   }
# 
define common::archive::download ($url,
																	$ensure           = present,
																	$checksum         = true,
																	$digest_url       = '',
																	$digest_string    = '',
																	$digest_type      = 'md5',
																	$timeout          = 120,
																	$src_target       = '/usr/src',
																	$follow_redirects = false) {

	if !defined(Package['curl']) {
		package { 'curl':
			ensure => present,
		}
	}	
		
	if($follow_redirects == true){
		$curl_extra_opts = '-L'
	} else {
		$curl_extra_opts = ''
	}

	case $checksum {
		true : {
			case $digest_type {
				'md5','sha1','sha224','sha256','sha384','sha512' : { 
					$checksum_cmd = "cd ${src_target} && /usr/bin/${digest_type}sum -c ${name}.${digest_type}" 
				}
				default: { fail 'Unimplemented digest type' }
			}
    
			if $digest_url != '' and $digest_content != '' {
				fail 'digest_url and digest_content should not be used together !'
			}
    
			if $digest_content == '' {
				case $ensure {
					present: {
						if $digest_url == '' {
							$digest_src = "${url}.${digest_type}"
 						} else {
							$digest_src = $digest_url
						}
    
						exec { "download digest of archive ${name}":
							command => "/usr/bin/curl ${curl_extra_opts} -o ${src_target}/${name}.${digest_type} ${digest_src}",
							creates => "${src_target}/${name}.${digest_type}",
							timeout => $timeout,
							notify  => Exec["download archive ${name} and check sum"],
							require => Package['curl'],
						}
					}
					absent: {
						file { "${src_target}/${name}.${digest_type}":
							ensure => absent,
							purge  => true,
							force  => true,
						}
					}
				}
			}
    
			if $digest_string != '' {
				case $ensure {
					present: {
						file {"${src_target}/${name}.${digest_type}":
							ensure  => $ensure,
							content => "${digest_string} *${name}",
							notify  => Exec["download archive ${name} and check sum"],
						}
					}
					absent: {
						file {"${src_target}/${name}.${digest_type}":
							ensure => absent,
							purge  => true,
							force  => true,
						}
					}
				}
			}
		}
		false :  { notice 'No checksum for this archive' }
		default: { fail ( "Unknown checksum value: '${checksum}'" ) }
	}
 
	case $ensure {
		present: {
			$on_error = "(rm -f ${src_target}/${name} ${src_target}/${name}.${digest_type} && exit 1)"
			exec { "download archive ${name} and check sum":
				command     => $checksum ? {
					true    => "/bin/sh -c '(/usr/bin/curl ${curl_extra_opts} -o ${src_target}/${name} ${url} && ${checksum_cmd}) || ${on_error}'",
					false   => "/usr/bin/curl ${curl_extra_opts} -o ${src_target}/${name} ${url}",
					default => fail ( "Unknown checksum value: '${checksum}'" ),
				},
				creates     => "${src_target}/${name}",
				logoutput   => true,
				timeout     => $timeout,
				refreshonly => $checksum ? {
					true    => true,
					default => undef,
				},
				require     => Package['curl'],
			}
		}
		absent: {
			file { "${src_target}/${name}":
				ensure => absent,
				purge  => true,
				force  => true,
			}
		}
		default: { fail ( "Unknown ensure value: '${ensure}'" ) }
	}
}
