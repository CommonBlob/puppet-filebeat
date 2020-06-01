# metricbeat::install::linux
#
# Install the linux metricbeat package
#
# @summary A simple class to install the metricbeat package
#
class metricbeat::install::linux {
  if $::kernel != 'Linux' {
    fail('metricbeat::install::linux shouldn\'t run on Windows')
  }

  package {'metricbeat':
    ensure => $metricbeat::package_ensure,
  }
}
