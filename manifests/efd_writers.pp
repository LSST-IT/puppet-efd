class efd::efd_writers(
  String $lsst_sal_repo_url,
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

  package{'OpenSpliceDDS':
    ensure  => '6.9.0-1',
    require => Yumrepo['lsst_sal']
  }

  package{ 'ts_EFDruntime':
    ensure  => '3.9.0',
    require => Package['OpenSpliceDDS'],
    notify  => Exec['Systemd daemon reload']
  }

  exec{'Systemd daemon reload':
    path        => [ '/usr/bin', '/bin', '/usr/sbin' , '/usr/local/bin'],
    command     => 'systemctl daemon-reload',
    refreshonly => true
  }

  #$ts_efd_writers = lookup('ts::efd::ts_efd_writers')
  #$ts_xml_subsystems = lookup('ts_xml::ts_xml_subsystems')

  $ts_sal_path = "/opt/lsst/ts_sal/"

  # Still don't know where the setup.env file will be
  file_line{ 'Add LSST_EFD_HOST variable' :
    path => "${ts_sal_path}/setupEFD.env",
    line => 'export LSST_EFD_HOST=localhost',
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
