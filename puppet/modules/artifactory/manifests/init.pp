# Class: artifactory
#
# This module manages artifactory
#
# Parameters:
#
# Actions:
#
# Requires:
#	Class['tomcat']
#   Tomcat::Webapp[$username]
#
#   See https://github.com/jurgenlust/puppet-tomcat
#
# Sample Usage:
#
class artifactory(
	$user = $::luser,	
  $group = 'staff',
	$port_prefix = 81,
	$version = "3.0.3",
	$contextroot = "artifactory",
	$webapp_base = "/opt/tomcat"
){
# configuration	
	$zip = "artifactory-${version}.zip"
	$war = "artifactory-${version}.war"
	$download_url = "http://sourceforge.net/projects/artifactory/files/artifactory/${version}/${zip}/download"
	$artifactory_dir = "${webapp_base}/artifactory"
	$artifactory_home = "/Users/wolfs/.artifactory"
	$artifactory_zip_dir = "${artifactory_dir}/download"
	$artifactory_wars_dir = "${artifactory_dir}/war"
	$artifactory_war_dir = "${artifactory_wars_dir}/${version}"
  # $artifactory_home = "${artifactory_dir}/artifactory-home"
	
	$webapp_context = $contextroot ? {
	  '/' => '',	
    '' => '',
    default  => "/${contextroot}"
  }
    
  $webapp_war = $contextroot ? {
  	'' => "ROOT.war",
   	'/' => "ROOT.war",
   	default => "${contextroot}.war"	
  }
    
	file { "${artifactory_zip_dir}":
		ensure => directory,
    owner   => "$user",
    group  => "staff",
	}

	file { ["${artifactory_wars_dir}", "${artifactory_war_dir}"]:
		ensure => directory,
    owner   => "$user",
    group  => "staff",
	}

    #	file { $artifactory_home:
    #		ensure => directory,
    #		mode => 0755,
    #		owner => $user,
    #		group => $group,
    #	}
    #
	exec { "download-artifactory":
		command => "/opt/boxen/homebrew/bin/wget -O ${artifactory_zip_dir}/${zip} ${download_url}",
		creates => "${artifactory_zip_dir}/${zip}",
		timeout => 1200,
    require => File["${artifactory_zip_dir}"],
	}
	
	file { "artifactory-zip-file":
    path    => "${artifactory_zip_dir}/${zip}",
		ensure  => file,
		require => Exec["download-artifactory"],
	}
	
	exec { "extract-artifactory" :
		command => "/usr/bin/unzip -j ${zip} artifactory-${version}/webapps/artifactory.war -d ${artifactory_war_dir}",
		creates => "${artifactory_war_dir}/artifactory.war",
		require => File["artifactory-zip-file", "${artifactory_war_dir}"],
		cwd => "${artifactory_zip_dir}",
		user => $user 	
	}
	
  #
  ## the Artifactory war file
  file { 'artifactory-war':
  	path => "${artifactory_war_dir}/artifactory.war", 
  	ensure => file,
  	owner => $user,
  	group => 'staff',
  	require => Exec["extract-artifactory"],
  }

 	file { "${artifactory_dir}/webapps/${webapp_war}":
    ensure  => link,
    target  => "${artifactory_war_dir}/artifactory.war",
 		require => File["artifactory-war"],
    notify  => Service["dev.tomcat.artifactory"],
 	}

  
  #	tomcat::webapp { $user:
  #		username => $user,
  #		webapp_base => $webapp_base,
  #		number => $number,
  #		java_opts => "-server -Xms128m -Xmx512m -XX:MaxPermSize=256m -Djava.awt.headless=true -Dartifactory.home=${artifactory_home}",
  #		description => "Artifactory",
  #		service_require => [File['artifactory-war'], File[$artifactory_home]],
  #		require => Class["tomcat"],
  #	}
  tomcat::instance { "artifactory":
    ensure      => present,
    http_port   => "${port_prefix}80",
    ajp_port    => "${port_prefix}09",
    server_port => "${port_prefix}05",
  }

}
