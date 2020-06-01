# metricbeat::service
#
# Manage the metricbeat service
#
# @summary Manage the metricbeat service
class metricbeat::service {
  service { 'metricbeat':
    ensure   => $metricbeat::real_service_ensure,
    enable   => $metricbeat::real_service_enable,
    provider => $metricbeat::service_provider,
  }

  $major_version                  = $metricbeat::major_version
  $systemd_beat_log_opts_override = $metricbeat::systemd_beat_log_opts_override

  #make sure puppet client version 6.1+ with metricbeat version 7+, running on systemd
  if ( versioncmp( $major_version, '7'   ) >= 0 and
    $::service_provider == 'systemd' ) {

    if ( versioncmp( $::clientversion, '6.1' ) >= 0 ) {

      unless $systemd_beat_log_opts_override == undef {
        $ensure_overide = 'present'
      } else {
        $ensure_overide = 'absent'
      }

      ensure_resource('file',
        $metricbeat::systemd_override_dir,
        {
          ensure => 'directory',
        }
      )

      file { "${metricbeat::systemd_override_dir}/logging.conf":
        ensure  => $ensure_overide,
        content => template($metricbeat::systemd_beat_log_opts_template),
        require => File[$metricbeat::systemd_override_dir],
        notify  => Service['metricbeat'],
      }

    } else {

      unless $systemd_beat_log_opts_override == undef {
        $ensure_overide = 'present'
      } else {
        $ensure_overide = 'absent'
      }

      if !defined(File[$metricbeat::systemd_override_dir]) {
        file{$metricbeat::systemd_override_dir:
          ensure => 'directory',
        }
      }

      file { "${metricbeat::systemd_override_dir}/logging.conf":
        ensure  => $ensure_overide,
        content => template($metricbeat::systemd_beat_log_opts_template),
        require => File[$metricbeat::systemd_override_dir],
        notify  => Service['metricbeat'],
      }

      unless defined('systemd') {
        warning('You\'ve specified an $systemd_beat_log_opts_override varible on a system running puppet version < 6.1 and not declared "systemd" resource See README.md for more information') # lint:ignore:140chars
      }
    }
  }

}
