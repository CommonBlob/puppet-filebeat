# metricbeat::config
#
# Manage the configuration files for metricbeat
#
# @summary A private class to manage the metricbeat config file
class metricbeat::config {
  $major_version = $metricbeat::major_version

  if has_key($metricbeat::setup, 'ilm.policy') {
    file {"${metricbeat::config_dir}/ilm_policy.json":
      content => to_json({'policy' => $metricbeat::setup['ilm.policy']}),
      notify  => Service['metricbeat'],
      require => File['metricbeat-config-dir'],
    }
    $setup = $metricbeat::setup - 'ilm.policy' + {'ilm.policy_file' => "${metricbeat::config_dir}/ilm_policy.json"}
  } else {
    $setup = $metricbeat::setup
  }

  if versioncmp($major_version, '6') >= 0 {
    $metricbeat_config_temp = delete_undef_values({
      'shutdown_timeout'  => $metricbeat::shutdown_timeout,
      'name'              => $metricbeat::beat_name,
      'tags'              => $metricbeat::tags,
      'max_procs'         => $metricbeat::max_procs,
      'cloud_id'          => $metricbeat::cloud_id,
      'cloud_auth'        => $metricbeat::cloud_auth,
      'fields'            => $metricbeat::fields,
      'fields_under_root' => $metricbeat::fields_under_root,
      'metricbeat'          => {
        'config.inputs' => {
          'enabled' => true,
          'path'    => "${metricbeat::config_dir}/*.yml",
        },
        'config.modules' => {
          'enabled' => $metricbeat::enable_conf_modules,
          'path'    => "${metricbeat::modules_dir}/*.yml",
        },
        'shutdown_timeout'   => $metricbeat::shutdown_timeout,
        'modules'           => $metricbeat::modules,
      },
      'http'              => $metricbeat::http,
      'output'            => $metricbeat::outputs,
      'shipper'           => $metricbeat::shipper,
      'logging'           => $metricbeat::logging,
      'runoptions'        => $metricbeat::run_options,
      'processors'        => $metricbeat::processors,
      'monitoring'        => $metricbeat::monitoring,
      'setup'             => $setup,
    })
    # Add the 'xpack' section if supported (version >= 6.1.0) and not undef
    if $metricbeat::xpack and versioncmp($metricbeat::package_ensure, '6.1.0') >= 0 {
      $metricbeat_config = deep_merge($metricbeat_config_temp, {'xpack' => $metricbeat::xpack})
    }
    else {
      $metricbeat_config = $metricbeat_config_temp
    }
  } else {
    $metricbeat_config_temp = delete_undef_values({
      'shutdown_timeout'  => $metricbeat::shutdown_timeout,
      'name'              => $metricbeat::beat_name,
      'tags'              => $metricbeat::tags,
      'queue_size'        => $metricbeat::queue_size,
      'max_procs'         => $metricbeat::max_procs,
      'cloud_id'          => $metricbeat::cloud_id,
      'cloud_auth'        => $metricbeat::cloud_auth,
      'fields'            => $metricbeat::fields,
      'fields_under_root' => $metricbeat::fields_under_root,
      'metricbeat'          => {
        'spool_size'       => $metricbeat::spool_size,
        'idle_timeout'     => $metricbeat::idle_timeout,
        'registry_file'    => $metricbeat::registry_file,
        'publish_async'    => $metricbeat::publish_async,
        'config_dir'       => $metricbeat::config_dir,
        'shutdown_timeout' => $metricbeat::shutdown_timeout,
      },
      'output'            => $metricbeat::outputs,
      'shipper'           => $metricbeat::shipper,
      'logging'           => $metricbeat::logging,
      'runoptions'        => $metricbeat::run_options,
      'processors'        => $metricbeat::processors,
    })
    # Add the 'modules' section if supported (version >= 5.2.0)
    if versioncmp($metricbeat::package_ensure, '5.2.0') >= 0 {
      $metricbeat_config = deep_merge($metricbeat_config_temp, {'modules' => $metricbeat::modules})
    }
    else {
      $metricbeat_config = $metricbeat_config_temp
    }
  }

  if 'metricbeat_version' in $facts and $facts['metricbeat_version'] != false {
    $skip_validation = versioncmp($facts['metricbeat_version'], $metricbeat::major_version) ? {
      -1      => true,
      default => false,
    }
  } else {
    $skip_validation = false
  }

  case $::kernel {
    'Linux'   : {
      $validate_cmd = ($metricbeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => $major_version ? {
          '5'     => "${metricbeat::metricbeat_path} -N -configtest -c %",
          default => "${metricbeat::metricbeat_path} -c % test config",
        },
      }

      file {'metricbeat.yml':
        ensure       => $metricbeat::file_ensure,
        path         => $metricbeat::config_file,
        content      => template($metricbeat::conf_template),
        owner        => $metricbeat::config_file_owner,
        group        => $metricbeat::config_file_group,
        mode         => $metricbeat::config_file_mode,
        validate_cmd => $validate_cmd,
        notify       => Service['metricbeat'],
        require      => File['metricbeat-config-dir'],
      }

      file {'metricbeat-config-dir':
        ensure  => $metricbeat::directory_ensure,
        path    => $metricbeat::config_dir,
        owner   => $metricbeat::config_dir_owner,
        group   => $metricbeat::config_dir_group,
        mode    => $metricbeat::config_dir_mode,
        recurse => $metricbeat::purge_conf_dir,
        purge   => $metricbeat::purge_conf_dir,
        force   => true,
      }
    } # end Linux

    'FreeBSD'   : {
      $validate_cmd = ($metricbeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => '/usr/local/sbin/metricbeat -N -configtest -c %',
      }

      file {'metricbeat.yml':
        ensure       => $metricbeat::file_ensure,
        path         => $metricbeat::config_file,
        content      => template($metricbeat::conf_template),
        owner        => $metricbeat::config_file_owner,
        group        => $metricbeat::config_file_group,
        mode         => $metricbeat::config_file_mode,
        validate_cmd => $validate_cmd,
        notify       => Service['metricbeat'],
        require      => File['metricbeat-config-dir'],
      }

      file {'metricbeat-config-dir':
        ensure  => $metricbeat::directory_ensure,
        path    => $metricbeat::config_dir,
        owner   => $metricbeat::config_dir_owner,
        group   => $metricbeat::config_dir_group,
        mode    => $metricbeat::config_dir_mode,
        recurse => $metricbeat::purge_conf_dir,
        purge   => $metricbeat::purge_conf_dir,
        force   => true,
      }
    } # end FreeBSD

    'OpenBSD'   : {
      $validate_cmd = ($metricbeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => $major_version ? {
          '5'     => "${metricbeat::metricbeat_path} -N -configtest -c %",
          default => "${metricbeat::metricbeat_path} -c % test config",
        },
      }

      file {'metricbeat.yml':
        ensure       => $metricbeat::file_ensure,
        path         => $metricbeat::config_file,
        content      => template($metricbeat::conf_template),
        owner        => $metricbeat::config_file_owner,
        group        => $metricbeat::config_file_group,
        mode         => $metricbeat::config_file_mode,
        validate_cmd => $validate_cmd,
        notify       => Service['metricbeat'],
        require      => File['metricbeat-config-dir'],
      }

      file {'metricbeat-config-dir':
        ensure  => $metricbeat::directory_ensure,
        path    => $metricbeat::config_dir,
        owner   => $metricbeat::config_dir_owner,
        group   => $metricbeat::config_dir_group,
        mode    => $metricbeat::config_dir_mode,
        recurse => $metricbeat::purge_conf_dir,
        purge   => $metricbeat::purge_conf_dir,
        force   => true,
      }
    } # end OpenBSD

    'Windows' : {
      $cmd_install_dir = regsubst($metricbeat::install_dir, '/', '\\', 'G')
      $metricbeat_path = join([$cmd_install_dir, 'Metricbeat', 'metricbeat.exe'], '\\')

      $validate_cmd = ($metricbeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => $major_version ? {
          '7'     => "\"${metricbeat_path}\" test config -c \"%\"",
          default => "\"${metricbeat_path}\" -N -configtest -c \"%\"",
        }
      }

      file {'metricbeat.yml':
        ensure       => $metricbeat::file_ensure,
        path         => $metricbeat::config_file,
        content      => template($metricbeat::conf_template),
        validate_cmd => $validate_cmd,
        notify       => Service['metricbeat'],
        require      => File['metricbeat-config-dir'],
      }

      file {'metricbeat-config-dir':
        ensure  => $metricbeat::directory_ensure,
        path    => $metricbeat::config_dir,
        recurse => $metricbeat::purge_conf_dir,
        purge   => $metricbeat::purge_conf_dir,
        force   => true,
      }
    } # end Windows

    default : {
      fail($metricbeat::kernel_fail_message)
    }
  }
}
