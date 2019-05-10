# EFD main class, used to create an EFD with everything.
class efd{
  include efd::efd_writers
  include efd::efd_mysql
  include efd::efd_influxdb
}
