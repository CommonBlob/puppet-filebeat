# This class installs the Elastic metricbeat log shipper and
# helps manage which files are shipped
#
# @example
# class { 'metricbeat':
#   outputs => {
#     'logstash' => {
#       'hosts' => [
#         'localhost:5044',
#       ],
#     },
#   },
# }
#
# @param package_ensure [String] The ensure parameter for the metricbeat package (default: present)
# @param manage_repo [Boolean] Whether or not the upstream (elastic) repo should be configured or not (default: true)
# @param manage_apt [Boolean] Whether or not the apt class should be explicitly called or not (default: true)
# @param major_version [Enum] The major version of Metricbeat to be installed.
# @param service_ensure [String] The ensure parameter on the metricbeat service (default: running)
# @param service_enable [String] The enable parameter on the metricbeat service (default: true)
# @param repo_priority [Integer] Repository priority.  yum and apt supported (default: undef)
# @param spool_size [Integer] How large the spool should grow before being flushed to the network (default: 2048)
# @param idle_timeout [String] How often the spooler should be flushed even if spool size isn't reached (default: 5s)
# @param publish_async [Boolean] If set to true metricbeat will publish while preparing the next batch of lines to send (defualt: false)
# @param config_dir [String] The directory where inputs should be defined (default: /etc/metricbeat/conf.d)
# @param config_dir_mode [String] The unix permissions mode set on the configuration directory (default: 0755)
# @param config_file_mode [String] The unix permissions mode set on configuration files (default: 0644)
# @param purge_conf_dir [Boolean] Should files in the input configuration directory not managed by puppet be automatically purged
# @param http [Hash] A hash of the http section of configuration
# @param outputs [Hash] Will be converted to YAML for the required outputs section of the configuration (see documentation, and above)
# @param shipper [Hash] Will be converted to YAML to create the optional shipper section of the metricbeat config (see documentation)
# @param logging [Hash] Will be converted to YAML to create the optional logging section of the metricbeat config (see documentation)
# @param modules [Array] Will be converted to YAML to create the optional modules section of the metricbeat config (see documentation)
# @param conf_template [String] The configuration template to use to generate the main metricbeat.yml config file
# @param download_url [String] The URL of the zip file that should be downloaded to install metricbeat (windows only)
# @param install_dir [String] Where metricbeat should be installed (windows only)
# @param tmp_dir [String] Where metricbeat should be temporarily downloaded to so it can be installed (windows only)
# @param shutdown_timeout [String] How long metricbeat waits on shutdown for the publisher to finish sending events
# @param beat_name [String] The name of the beat shipper (default: hostname)
# @param tags [Array] A list of tags that will be included with each published transaction
# @param max_procs [Integer] The maximum number of CPUs that can be simultaneously used
# @param fields [Hash] Optional fields that should be added to each event output
# @param fields_under_root [Boolean] If set to true, custom fields are stored in the top level instead of under fields
# @param processors [Array] Processors that will be added. Commonly used to create processors using hiera.
# @param monitoring [Hash] The monitoring section of the configuration file.
# @param inputs [Hash] or [Array] Inputs that will be created. Commonly used to create inputs using hiera
# @param setup [Hash] setup that will be created. Commonly used to create setup using hiera
# @param inputs_merge [Boolean] Whether $inputs should merge all hiera sources, or use simple automatic parameter lookup
# proxy_address [String] Proxy server to use for downloading files
# @param xpack [Hash] Configuration items to export internal stats to a monitoring Elasticsearch cluster
class metricbeat (
  String  $package_ensure                                             = $metricbeat::params::package_ensure,
  Boolean $manage_repo                                                = $metricbeat::params::manage_repo,
  Boolean $manage_apt                                                 = $metricbeat::params::manage_apt,
  Enum['5','6', '7'] $major_version                                   = $metricbeat::params::major_version,
  Variant[Boolean, Enum['stopped', 'running']] $service_ensure        = $metricbeat::params::service_ensure,
  Boolean $service_enable                                             = $metricbeat::params::service_enable,
  Optional[String]  $service_provider                                 = $metricbeat::params::service_provider,
  Optional[Integer] $repo_priority                                    = undef,
  Integer $spool_size                                                 = $metricbeat::params::spool_size,
  String  $idle_timeout                                               = $metricbeat::params::idle_timeout,
  Boolean $publish_async                                              = $metricbeat::params::publish_async,
  String  $config_file                                                = $metricbeat::params::config_file,
  Optional[String] $config_file_owner                                 = $metricbeat::params::config_file_owner,
  Optional[String] $config_file_group                                 = $metricbeat::params::config_file_group,
  String[4,4]  $config_dir_mode                                       = $metricbeat::params::config_dir_mode,
  String  $config_dir                                                 = $metricbeat::params::config_dir,
  String[4,4]  $config_file_mode                                      = $metricbeat::params::config_file_mode,
  Optional[String] $config_dir_owner                                  = $metricbeat::params::config_dir_owner,
  Optional[String] $config_dir_group                                  = $metricbeat::params::config_dir_group,
  Boolean $purge_conf_dir                                             = $metricbeat::params::purge_conf_dir,
  String  $modules_dir                                                = $metricbeat::params::modules_dir,
  Boolean $enable_conf_modules                                        = $metricbeat::params::enable_conf_modules,
  String  $cloud_auth                                                 = $metricbeat::params::cloud_auth,
  String  $cloud_id                                                   = $metricbeat::params::cloud_id,
  Hash    $http                                                       = $metricbeat::params::http,
  Hash    $outputs                                                    = $metricbeat::params::outputs,
  Hash    $shipper                                                    = $metricbeat::params::shipper,
  Hash    $logging                                                    = $metricbeat::params::logging,
  Hash    $run_options                                                = $metricbeat::params::run_options,
  String  $conf_template                                              = $metricbeat::params::conf_template,
  Optional[Variant[Stdlib::HTTPUrl, Stdlib::HTTPSUrl]] $download_url  = undef, # lint:ignore:140chars
  Optional[String]  $install_dir                                      = $metricbeat::params::install_dir,
  String  $tmp_dir                                                    = $metricbeat::params::tmp_dir,
  String  $shutdown_timeout                                           = $metricbeat::params::shutdown_timeout,
  String  $beat_name                                                  = $metricbeat::params::beat_name,
  Array   $tags                                                       = $metricbeat::params::tags,
  Optional[Integer] $max_procs                                        = $metricbeat::params::max_procs,
  Hash $fields                                                        = $metricbeat::params::fields,
  Boolean $fields_under_root                                          = $metricbeat::params::fields_under_root,
  Boolean $disable_config_test                                        = $metricbeat::params::disable_config_test,
  Array   $processors                                                 = [],
  Hash    $monitoring                                                 = {},
  Variant[Hash, Array] $inputs                                        = {},
  Hash    $setup                                                      = {},
  Array   $modules                                                    = [],
  Optional[Variant[Stdlib::HTTPUrl, Stdlib::HTTPSUrl]] $proxy_address = undef, # lint:ignore:140chars
  Stdlib::Absolutepath $metricbeat_path                                 = $metricbeat::params::metricbeat_path,
  Optional[Hash] $xpack                                               = $metricbeat::params::xpack,

  Integer $queue_size                                                 = 4096,
  String $registry_file                                               = 'metricbeat.yml',

  Optional[String] $systemd_beat_log_opts_override                    = undef,
  String $systemd_beat_log_opts_template                              = $metricbeat::params::systemd_beat_log_opts_template,
  String $systemd_override_dir                                        = $metricbeat::params::systemd_override_dir,

) inherits metricbeat::params {

  include ::stdlib

  $real_download_url = $download_url ? {
    undef   => "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-${package_ensure}-windows-${metricbeat::params::url_arch}.zip",
    default => $download_url,
  }

  if $config_file != $metricbeat::params::config_file {
    warning('You\'ve specified a non-standard config_file location - metricbeat may fail to start unless you\'re doing something to fix this')
  }

  if $package_ensure == 'absent' {
    $alternate_ensure = 'absent'
    $real_service_ensure = 'stopped'
    $file_ensure = 'absent'
    $directory_ensure = 'absent'
    $real_service_enable = false
  } else {
    $alternate_ensure = 'present'
    $file_ensure = 'file'
    $directory_ensure = 'directory'
    $real_service_ensure = $service_ensure
    $real_service_enable = $service_enable
  }

  # If we're removing metricbeat, do things in a different order to make sure
  # we remove as much as possible
  if $package_ensure == 'absent' {
    anchor { 'metricbeat::begin': }
    -> class { '::metricbeat::config': }
    -> class { '::metricbeat::install': }
    -> class { '::metricbeat::service': }
    -> anchor { 'metricbeat::end': }
  } else {
    anchor { 'metricbeat::begin': }
    -> class { '::metricbeat::install': }
    -> class { '::metricbeat::config': }
    -> class { '::metricbeat::service': }
    -> anchor { 'metricbeat::end': }
  }

  if $package_ensure != 'absent' {
    if !empty($inputs) {
      if $inputs =~ Array {
        create_resources('metricbeat::input', { 'inputs' => { pure_array => true } })
      } else {
        create_resources('metricbeat::input', $inputs)
      }
    }
  }
}
