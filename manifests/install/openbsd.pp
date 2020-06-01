# to manage metricbeat installation on OpenBSD
class metricbeat::install::openbsd {
  package {'metricbeat':
    ensure => $metricbeat::package_ensure,
  }
}
