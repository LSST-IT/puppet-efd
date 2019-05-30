# EFD main class, used to create an EFD with everything.
class efd{
  include efd::efd_writers
  include efd::efd_mysql
  include efd::efd_influxdb

  #This is the user to be used within the EFD Writers
  user{ 'salmgr':
    ensure     => 'present',
    uid        => '501' ,
    gid        => '500',
    home       => '/home/salmgr',
    managehome => true,
    require    => Group['lsst'],
    password   => lookup('salmgr_pwd'),
  }

}
