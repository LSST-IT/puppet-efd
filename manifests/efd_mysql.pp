# This class aims to configure a MySQL instance to be used as EFD Database
class efd::efd_mysql(
  String $mysql_admin_password,
  String $efd_user,
  String $efd_password,
){

  package { 'mariadb':
    ensure => installed,
  }

  package { 'mariadb-server':
    ensure => installed,
    notify => Exec['Mysql password reset']
  }

  file{ '/etc/my.cnf.d/efd.cnf' :
    ensure  => present,
    content => "[mysql]\nuser=${efd_user}\npassword=${efd_password}\n",
    require => [Package['mariadb'], Package['mariadb-server']]
  }

  package { 'mariadb-devel':
    ensure => installed,
  }

  # Services definition

  # The service must start just after the schema is downloaded.
  service { 'mariadb':
    ensure  => running,
    enable  => true,
    require => [File['/etc/my.cnf.d/efd.cnf']]
  }
  firewalld_service { 'Allow mysql port on firewalld':
    ensure  => 'present',
    service => 'mysql',
  }

exec{ 'Adjust SELinux to allow MySQL':
    path        => [ '/usr/bin', '/bin', '/usr/sbin' , '/usr/local/bin'],
    refreshonly => true,
    command     => 'setsebool -P nis_enabled 1 ; setsebool -P mysql_connect_any 1',
    onlyif      => "test ! -z $\"(which setsebool)\"" # This executes the command only if setsebool command exists
  }

  exec{ 'Mysql password reset':
    path        => [ '/usr/bin', '/bin', '/usr/sbin' , '/usr/local/bin'],
    command     => "mysqladmin --user=root password ${mysql_admin_password}",
    refreshonly => true,
    require     => [Service['mariadb']],
    notify      => [Exec['Executing initial setup']]
  }

  exec{ 'Executing initial setup' :
    path        => [ '/usr/bin', '/bin', '/usr/sbin' , '/usr/local/bin'],
    command     => "sleep 10; mysql -u root -p'${mysql_admin_password}' -e \
                \"CREATE DATABASE EFD; CREATE USER ${efd_user}@localhost IDENTIFIED BY '${efd_password}'; \
                GRANT ALL PRIVILEGES ON EFD.* TO ${efd_user}@localhost ; \"",
    refreshonly => true,
    require     => [Package['mariadb-server'],
                    Exec['Mysql password reset'],
                    Service['mariadb'],
                    #Exec['Adjust SELinux to allow MySQL']
                ]
  }



}
