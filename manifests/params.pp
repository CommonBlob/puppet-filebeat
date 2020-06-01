# metricbeat::params
#
# Set a number of default parameters
#
# @summary Set a bunch of default parameters
class metricbeat::params {
  $service_ensure           = running
  $service_enable           = true
  $spool_size               = 2048
  $idle_timeout             = '5s'
  $publish_async            = false
  $shutdown_timeout         = '0'
  $beat_name                = $::fqdn
  $cloud_auth               = undef
  $cloud_id                 = undef
  $tags                     = []
  $max_procs                = undef
  $config_file_mode         = '0644'
  $config_dir_mode          = '0755'
  $purge_conf_dir           = true
  $enable_conf_modules      = false
  $fields                   = {}
  $fields_under_root        = false
  $http                     = {}
  $outputs                  = {}
  $shipper                  = {}
  $logging                  = {}
  $run_options              = {}
  $modules                  = []
  $kernel_fail_message      = "${::kernel} is not supported by metricbeat."
  $osfamily_fail_message    = "${::osfamily} is not supported by metricbeat."
  $conf_template            = "${module_name}/pure_hash.yml.erb"
  $disable_config_test      = false
  $xpack                    = undef
  $systemd_override_dir     = '/etc/systemd/system/metricbeat.service.d'
  $systemd_beat_log_opts_template = "${module_name}/systemd/logging.conf.erb"

  # These are irrelevant as long as the template is set based on the major_version parameter
  # if versioncmp('1.9.1', $::rubyversion) > 0 {
  #   $conf_template = "${module_name}/metricbeat.yml.ruby18.erb"
  # } else {
  #   $conf_template = "${module_name}/metricbeat.yml.erb"
  # }
  #

  # Archlinux and OpenBSD have proper packages in the official repos
  # we shouldn't manage the repo on them
  case $facts['os']['family'] {
    'Archlinux': {
      $manage_repo = false
      $manage_apt  = false
      $metricbeat_path = '/usr/bin/metricbeat'
      $major_version = '7'
    }
    'OpenBSD': {
      $manage_repo = false
      $manage_apt  = false
      $metricbeat_path = '/usr/local/bin/metricbeat'
      # lint:ignore:only_variable_string
      $major_version = versioncmp('6.3', $::kernelversion) < 0 ? {
      # lint:endignore
        true    => '6',
        default => '5'
      }
    }
    default: {
      $manage_repo = true
      $manage_apt  = true
      $metricbeat_path = '/usr/share/metricbeat/bin/metricbeat'
      $major_version = '7'
    }
  }
  case $::kernel {
    'Linux'   : {
      $package_ensure    = present
      $config_file       = '/etc/metricbeat/metricbeat.yml'
      $config_dir        = '/etc/metricbeat/conf.d'
      $config_file_owner = 'root'
      $config_file_group = 'root'
      $config_dir_owner  = 'root'
      $config_dir_group  = 'root'
      $modules_dir        = '/etc/metricbeat/modules.d'
      # These parameters are ignored if/until tarball installs are supported in Linux
      $tmp_dir         = '/tmp'
      $install_dir     = undef
      case $::osfamily {
        'RedHat': {
          $service_provider = 'redhat'
        }
        default: {
          $service_provider = undef
        }
      }
      $url_arch        = undef
    }

    'FreeBSD': {
      $package_ensure    = present
      $config_file       = '/usr/local/etc/metricbeat.yml'
      $config_dir        = '/usr/local/etc/metricbeat.d'
      $config_file_owner = 'root'
      $config_file_group = 'wheel'
      $config_dir_owner  = 'root'
      $config_dir_group  = 'wheel'
      $modules_dir       = '/usr/local/etc/metricbeat.modules.d'
      $tmp_dir           = '/tmp'
      $service_provider  = undef
      $install_dir       = undef
      $url_arch          = undef
    }

    'OpenBSD': {
      $package_ensure    = present
      $config_file       = '/etc/metricbeat/metricbeat.yml'
      $config_dir        = '/etc/metricbeat/conf.d'
      $config_file_owner = 'root'
      $config_file_group = 'wheel'
      $config_dir_owner  = 'root'
      $config_dir_group  = 'wheel'
      $modules_dir        = '/etc/metricbeat/modules.d'
      $tmp_dir           = '/tmp'
      $service_provider  = undef
      $install_dir       = undef
      $url_arch          = undef
    }

    'Windows' : {
      $package_ensure   = '7.1.0'
      $config_file_owner = 'Administrator'
      $config_file_group = undef
      $config_dir_owner = 'Administrator'
      $config_dir_group = undef
      $config_file      = 'C:/Program Files/Metricbeat/metricbeat.yml'
      $config_dir       = 'C:/Program Files/Metricbeat/conf.d'
      $modules_dir      = 'C:/Program Files/Metricbeat/modules.d'
      $install_dir      = 'C:/Program Files'
      $tmp_dir          = 'C:/Windows/Temp'
      $service_provider = undef
      $url_arch         = $::architecture ? {
        'x86'   => 'x86',
        'x64'   => 'x86_64',
        default => fail("${::architecture} is not supported by metricbeat."),
      }
    }

    default : {
      fail($kernel_fail_message)
    }
  }
}
