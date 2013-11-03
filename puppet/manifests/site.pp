include jenkins

class { 'tomcat':
  sources => true,
}

tomcat::instance { "artifactory":
  ensure    => present,
  http_port => 8180,
  setenv    => [ 'ARTIFACTORY_HOME=/srv/tomcat/artifactory/home']
}

file { '/srv/tomcat/artifactory/webapps/artifactory.war':
  ensure => present,
  source => '/vagrant/files/artifactory.war',
}

file { '/srv/tomcat/artifactory/home':
  ensure => directory,
  owner  => tomcat,
  group  => tomcat,
}

user { 'ci':
  ensure     => present,
  groups     => ['users'],
  home       => '/home/ci',
  managehome => true,
  shell      => '/bin/bash',
  uid        => 7250,
  password   => 'jenkins'
}
