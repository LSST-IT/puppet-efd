class efd::efd_writers(
  String $lsst_sal_repo_url,
  String $lsst_efd_host,
  String $ts_EFDruntime_version,
  String $ts_sal_path,
  String $setup_filename,
  Array $efdwriter_topic_type,
  Array $efdwriters_subsystem_list,
  Array $db_type,
){

  # configure the repo we want to use
  yumrepo { 'lsst_sal':
    enabled  => 1,
    descr    => 'LSST Sal Repo',
    baseurl  => $lsst_sal_repo_url,
    gpgcheck => 0,
  }

  # ts_EFDruntime will resolve its own dependencies and will install the rigth version of OpenSpliceDDS
  package{ 'ts_EFDruntime':
    ensure => $ts_EFDruntime_version,
    notify => Exec['Systemd daemon reload']
  }

  exec{'Systemd daemon reload':
    path        => [ '/usr/bin', '/bin', '/usr/sbin' , '/usr/local/bin'],
    command     => 'systemctl daemon-reload',
    refreshonly => true
  }

  file{ "${ts_sal_path}/${setup_filename}":
    ensure => present,
  }

  file_line{ 'Add LSST_EFD_HOST variable' :
    path    => "${ts_sal_path}/${setup_filename}",
    line    => "export LSST_EFD_HOST=${lsst_efd_host}",
    require => File["${ts_sal_path}/${setup_filename}"]
  }

  $efdwriters_subsystem_list.each | String $subsystem | {
    $efdwriter_topic_type.each | String $writer | {
        $db_type.each | String $db | {
          service{ "${subsystem}_${writer}_${db}writer.service":
            ensure  => running,
            require => Package['ts_EFDruntime']
          }
        }
    }
  }

}
