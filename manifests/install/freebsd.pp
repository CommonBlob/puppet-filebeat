# metricbeat::install::freebsd
#
# Install the FreeBSD metricbeat package
#
# @summary A simple class to install the metricbeat package
#
class metricbeat::install::freebsd {

  # metricbeat, heartbeat, metricbeat, packetbeat are all contained in a
  # single FreeBSD Package (see https://www.freshports.org/sysutils/beats/ )
  ensure_packages (['beats'], {ensure => $metricbeat::package_ensure})

}
