# metricbeat::install
#
# A private class to manage the installation of Metricbeat
#
# @summary A private class that manages the install of Metricbeat
class metricbeat::install {
  anchor { 'metricbeat::install::begin': }

  case $::kernel {
    'Linux':   {
      class{ '::metricbeat::install::linux':
        notify => Class['metricbeat::service'],
      }
      Anchor['metricbeat::install::begin'] -> Class['metricbeat::install::linux'] -> Anchor['metricbeat::install::end']
      if $::metricbeat::manage_repo {
        class { '::metricbeat::repo': }
        Class['metricbeat::repo'] -> Class['metricbeat::install::linux']
      }
    }
    'FreeBSD': {
      class{ '::metricbeat::install::freebsd':
        notify => Class['metricbeat::service'],
      }
      Anchor['metricbeat::install::begin'] -> Class['metricbeat::install::freebsd'] -> Anchor['metricbeat::install::end']
    }
    'OpenBSD': {
      class{'metricbeat::install::openbsd':}
      Anchor['metricbeat::install::begin'] -> Class['metricbeat::install::openbsd'] -> Anchor['metricbeat::install::end']
    }
    'Windows': {
      class{'::metricbeat::install::windows':
        notify => Class['metricbeat::service'],
      }
      Anchor['metricbeat::install::begin'] -> Class['metricbeat::install::windows'] -> Anchor['metricbeat::install::end']
    }
    default:   {
      fail($metricbeat::kernel_fail_message)
    }
  }

  anchor { 'metricbeat::install::end': }

}
