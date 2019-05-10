# This class aims to configure a InfluxDB instance to be used as EFD Database
class efd::efd_influxdb(
  String $influx_admin_user,
  String $influx_admin_password,
  String $efd_user,
  String $efd_password,
){
  class {'influxdb::server':
    ensure                 => 'present',
    service_enabled        => true,
    http_enabled           => true,
    http_auth_enabled      => true,
    http_log_enabled       => true,
    http_write_tracing     => false,
    http_pprof_enabled     => true,
    meta_bind_address      => ':8088',
    meta_http_bind_address => ':8091',
    http_bind_address      => ':8086',
    http_https_enabled     => false,
    notify                 => Exec['Create admin user on influxdb'],
  }

  firewalld_port { 'InfluxDB Main Port':
    ensure   => present,
    port     => '8086',
    protocol => 'tcp',
    require  => Service['firewalld'],
  }

  firewalld_port { 'InfluxDB Internodes Port':
    ensure   => present,
    port     => '8091',
    protocol => 'tcp',
    require  => Service['firewalld'],
  }

  exec{'Create admin user on influxdb':
    path    => ['/usr/bin','/usr/sbin'],
    command => "influx -execute \"CREATE USER ${influx_admin_user} WITH PASSWORD '${influx_admin_password}' WITH ALL PRIVILEGES\"",
    onlyif  => "test $(influx -execute 'show databases' -username '${influx_admin_user}' \
                -password '${influx_admin_password}' &> /dev/null; echo $? ) -eq 1",
    require => Service['influxdb'],
  }

  ~> exec{'Create EFD database on influxdb':
    path    => ['/usr/bin','/usr/sbin'],
    command => "influx -username '${influx_admin_user}' -password '${influx_admin_password}' \
                -execute \"CREATE DATABASE EFD\"",
    require => [Exec['Create admin user on influxdb'],Service['influxdb']],
    onlyif  => "test $(influx -username '${influx_admin_user}' -password '${influx_admin_password}' \
                -execute \"SHOW DATABASES\" | grep EFD | wc -l ) -lt 1",

  }

  ~> exec{'Create EFD user on influxdb':
    path    => ['/usr/bin','/usr/sbin'],
    command => "influx -username '${influx_admin_user}' -password '${influx_admin_password}' \
                -execute \"CREATE USER ${efd_user} WITH PASSWORD '${efd_password}'\"",
    require => [Exec['Create admin user on influxdb'],Exec['Create EFD database on influxdb'], Service['influxdb']],
    onlyif  => "test $(influx -username '${influx_admin_user}' -password '${influx_admin_password}' \
                -execute \"SHOW USERS\" | grep ${efd_user} | wc -l ) -lt 1",

  }

  ~> exec{'Grant all access to EFD':
    path    => ['/usr/bin','/usr/sbin'],
    command => "influx -username '${influx_admin_user}' -password '${influx_admin_password}' \
                -execute \"GRANT ALL ON EFD TO ${efd_user}\"",
    require => [
                  Exec['Create admin user on influxdb'],
                  Exec['Create EFD database on influxdb'],
                  Exec['Create EFD user on influxdb']
                ],
    onlyif  => "test $(influx -username '${influx_admin_user}' -password '${influx_admin_password}' \
                -execute \"SHOW GRANTS FOR ${efd_user}\" | grep -i EFD | wc -l ) -lt 1",
  }

}
