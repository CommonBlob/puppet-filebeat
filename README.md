# puppet-metricbeat

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with metricbeat](#setup)
    - [What metricbeat affects](#what-metricbeat-affects)
    - [Setup requirements](#setup-requirements)
    - [Beginning with metricbeat](#beginning-with-metricbeat)
3. [Usage - Configuration options and additional functionality](#usage)
    - [Adding an Input](#adding-an-input)
      - [Multiline Logs](#multiline-logs)
      - [JSON logs](#json-logs)
    - [Inputs in hiera](#inputs-in-hiera)
    - [Usage on Windows](#usage-on-windows)
    - [Processors](#processors)
    - [Index Lifecycle Management](#index-lifecycle-management)
4. [Reference](#reference)
    - [Public Classes](#public-classes)
    - [Private Classes](#private-classes)
    - [Public Defines](#public-defines)
5. [Limitations - OS compatibility, etc.](#limitations)
    - [Pre-1.9.1 Ruby](#pre-191-ruby)
    - [Using config_file](#using-config_file)
6. [Development - Guide for contributing to the module](#development)

## Description

The `metricbeat` module installs and configures the [metricbeat log shipper](https://www.elastic.co/products/beats/metricbeat) maintained by elastic.

## Setup

### What metricbeat affects

By default `metricbeat` adds a software repository to your system, and installs metricbeat along
with required configurations.

### Upgrading to metricbeat 7.x

To upgrade to metricbeat 7.x, simply set `$metricbeat::major_version` to `7` and `$metricbeat::package_ensure` to `latest` (or whichever version of 7.x you want, just not present).

You'll also need to change instances of `metricbeat::prospector` to `metricbeat::input` when upgrading to version 4.x of
this module.


### Setup Requirements

The `metricbeat` module depends on [`puppetlabs/stdlib`](https://forge.puppetlabs.com/puppetlabs/stdlib), and on
[`puppetlabs/apt`](https://forge.puppetlabs.com/puppetlabs/apt) on Debian based systems.

### Beginning with metricbeat

`metricbeat` can be installed with `puppet module install pcfens-metricbeat` (or with r10k, librarian-puppet, etc.)

The only required parameter, other than which files to ship, is the `outputs` parameter.

## Usage

All of the default values in metricbeat follow the upstream defaults (at the time of writing).

To ship files to [elasticsearch](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-configuration-details.html#elasticsearch-output):
```puppet
class { 'metricbeat':
  outputs => {
    'elasticsearch' => {
     'hosts' => [
       'http://localhost:9200',
       'http://anotherserver:9200'
     ],
     'loadbalance' => true,
     'cas'         => [
        '/etc/pki/root/ca.pem',
     ],
    },
  },
}

```

To ship log files through [logstash](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-configuration-details.html#logstash-output):
```puppet
class { 'metricbeat':
  outputs => {
    'logstash'     => {
     'hosts' => [
       'localhost:5044',
       'anotherserver:5044'
     ],
     'loadbalance' => true,
    },
  },
}

```

[Shipper](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-configuration-details.html#configuration-shipper) and
[logging](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-configuration-details.html#configuration-logging) options
can be configured the same way, and are documented on the [elastic website](https://www.elastic.co/guide/en/beats/metricbeat/current/index.html).

#### Multiline Logs

metricbeat inputs can handle multiline log entries. The `multiline`
parameter accepts a hash containing `pattern`, `negate`, `match`, `max_lines`, and `timeout`
as documented in the metricbeat [configuration documentation](https://www.elastic.co/guide/en/beats/metricbeat/current/multiline-examples.html).

#### JSON Logs

metricbeat inputs (versions >= 5.0) can natively decode JSON objects if they are stored one per line. The `json`
parameter accepts a hash containing `message_key`, `keys_under_root`, `overwrite_keys`, and `add_error_key`
as documented in the metricbeat [configuration documentation](https://www.elastic.co/guide/en/beats/metricbeat/5.5/configuration-metricbeat-options.html#config-json).

### Inputs in Hiera

Inputs can be defined in hiera using the `inputs` parameter. By default, hiera will not merge
input declarations down the hiera hierarchy. That behavior can be changed by configuring the
[lookup_options](https://docs.puppet.com/puppet/latest/reference/lookup_quick.html#setting-lookupoptions-in-data)
flag.

`inputs` can be a Hash that will follow all the parameters listed on this documentation or an
Array that will output as is to the input config file.

### Usage on Windows

When installing on Windows, this module will download the windows version of metricbeat from
[elastic](https://www.elastic.co/downloads/beats/metricbeat) to `C:\Temp` by default. The directory
can be overridden using the `tmp_dir` parameter. `tmp_dir` is not managed by this module,
but is expected to exist as a directory that puppet can write to.

### Processors

metricbeat 5.0 and greater includes a new libbeat feature for filtering and/or enhancing all
exported data through processors before being sent to the configured output(s). They can be
defined as a hash added to the class declaration (also used for automatically creating
processors using hiera), or as their own defined resources.

To drop the offset and input_type fields from all events:

```puppet
class {'metricbeat':
  processors => [
    {
      'drop_fields' => {
        'fields' => ['input_type', 'offset'],
      }
    }
  ],
}
```

To drop all events that have the http response code equal to 200:
input
```puppet
class {'metricbeat':
  processors => [
    {
      'drop_event' => {
        'when' => {'equals' => {'http.code' => 200}}
      }
    }
  ],
}
```

Now to combine these examples into a single definition:

```puppet
class {'metricbeat':
  processors => [
    {
      'drop_fields' => {
        'params'   => {'fields' => ['input_type', 'offset']},
        'priority' => 1,
      }
    },
    {
      'drop_event' => {
        'when'     => {'equals' => {'http.code' => 200}},
        'priority' => 2,
      }
    }
  ],
}
```

For more information please review the documentation [here](https://www.elastic.co/guide/en/beats/metricbeat/5.1/configuration-processors.html).

#### Processors in Hiera

Processors can be declared in hiera using the `processors` parameter. By default, hiera will not merge
processor declarations down the hiera hierarchy. That behavior can be changed by configuring the
[lookup_options](https://docs.puppet.com/puppet/latest/reference/lookup_quick.html#setting-lookupoptions-in-data)
flag.

### Index Lifecycle Management

You can override the default metricbeat ILM policy by specifying `ilm.policy` hash in `metricbeat::setup` parameter:

```
metricbeat::setup:
  ilm.policy:
    phases:
      hot:
        min_age: "0ms"
        actions:
          rollover:
            max_size: "10gb"
            max_age: "1d"
```

## Reference
 - [**Public Classes**](#public-classes)
    - [Class: metricbeat](#class-metricbeat)
 - [**Private Classes**](#private-classes)
    - [Class: metricbeat::config](#class-metricbeatconfig)
    - [Class: metricbeat::install](#class-metricbeatinstall)
    - [Class: metricbeat::params](#class-metricbeatparams)
    - [Class: metricbeat::repo](#class-metricbeatrepo)
    - [Class: metricbeat::service](#class-metricbeatservice)
    - [Class: metricbeat::install::linux](#class-metricbeatinstalllinux)
    - [Class: metricbeat::install::windows](#class-metricbeatinstallwindows)
 - [**Public Defines**](#public-defines)
    - [Define: metricbeat::input](#define-metricbeatinput)
    - [Define: metricbeat::processors](#define-metricbeatprocessor)

### Public Classes

#### Class: `metricbeat`

Installs and configures metricbeat.

**Parameters within `metricbeat`**
- `package_ensure`: [String] The ensure parameter for the metricbeat package If set to absent,
  inputs and processors passed as parameters are ignored and everything managed by
  puppet will be removed. (default: present)
- `manage_repo`: [Boolean] Whether or not the upstream (elastic) repo should be configured or not (default: true)
- `major_version`: [Enum] The major version of metricbeat to install. Should be either `'5'` or `'6'`. The default value is `'6'`, except
   for OpenBSD 6.3 and earlier, which has a default value of `'5'`.
- `service_ensure`: [String] The ensure parameter on the metricbeat service (default: running)
- `service_enable`: [String] The enable parameter on the metricbeat service (default: true)
- `param repo_priority`: [Integer] Repository priority.  yum and apt supported (default: undef)
- `service_provider`: [String] The provider parameter on the metricbeat service (default: on RedHat based systems use redhat, otherwise undefined)
- `spool_size`: [Integer] How large the spool should grow before being flushed to the network (default: 2048)
- `idle_timeout`: [String] How often the spooler should be flushed even if spool size isn't reached (default: 5s)
- `publish_async`: [Boolean] If set to true metricbeat will publish while preparing the next batch of lines to transmit (default: false)
- `config_file`: [String] Where the configuration file managed by this module should be placed. If you think
  you might want to use this, read the [limitations](#using-config_file) first. Defaults to the location
  that metricbeat expects for your operating system.
- `config_dir`: [String] The directory where inputs should be defined (default: /etc/metricbeat/conf.d)
- `config_dir_mode`: [String] The permissions mode set on the configuration directory (default: 0755)
- `config_dir_owner`: [String] The owner of the configuration directory (default: root). Linux only.
- `config_dir_group`: [String] The group of the configuration directory (default: root). Linux only.
- `config_file_mode`: [String] The permissions mode set on configuration files (default: 0644)
- `config_file_owner`: [String] The owner of the configuration files, including inputs (default: root). Linux only.
- `config_file_group`: [String] The group of the configuration files, including inputs (default: root). Linux only.
- `purge_conf_dir`: [Boolean] Should files in the input configuration directory not managed by puppet be automatically purged
- `enable_conf_modules`: [Boolean] Should metricbeat.config.modules be enabled
- `modules_dir`: [String] The directory where module configurations should be defined (default: /etc/metricbeat/modules.d)
- `outputs`: [Hash] Will be converted to YAML for the required outputs section of the configuration (see documentation, and above)
- `shipper`: [Hash] Will be converted to YAML to create the optional shipper section of the metricbeat config (see documentation)
- `logging`: [Hash] Will be converted to YAML to create the optional logging section of the metricbeat config (see documentation)
- `systemd_beat_log_opts_override`: [String] Will overide the default `BEAT_LOG_OPTS=-e`. Required if using `logging` hash on systems running with systemd. required: Puppet 6.1+, metricbeat 7+,
- `modules`: [Array] Will be converted to YAML to create the optional modules section of the metricbeat config (see documentation)
- `modulesd`: [Hash] Used to fill in the templates stored in modules.d
- `conf_template`: [String] The configuration template to use to generate the main metricbeat.yml config file.
- `download_url`: [String] The URL of the zip file that should be downloaded to install metricbeat (windows only)
- `install_dir`: [String] Where metricbeat should be installed (windows only)
- `tmp_dir`: [String] Where metricbeat should be temporarily downloaded to so it can be installed (windows only)
- `shutdown_timeout`: [String] How long metricbeat waits on shutdown for the publisher to finish sending events
- `beat_name`: [String] The name of the beat shipper (default: hostname)
- `tags`: [Array] A list of tags that will be included with each published transaction
- `max_procs`: [Number] The maximum number of CPUs that can be simultaneously used
- `fields`: [Hash] Optional fields that should be added to each event output
- `fields_under_root`: [Boolean] If set to true, custom fields are stored in the top level instead of under fields
- `disable_config_test`: [Boolean] If set to true, configuration tests won't be run on config files before writing them.
- `processors`: [Array] Processors that should be configured.
- `monitoring`: [Hash] The monitoring.* components of the metricbeat configuration.
- `inputs`: [Hash] or [Array] Inputs that will be created. Commonly used to create inputs using hiera
- `setup`: [Hash] Setup that will be created. Commonly used to create setup using hiera
- `xpack`: [Hash] XPack configuration to pass to metricbeat

### Private Classes

#### Class: `metricbeat::config`

Creates the configuration files required for metricbeat (but not the inputs)

#### Class: `metricbeat::install`

Calls the correct installer class based on the kernel fact.

#### Class: `metricbeat::params`

Sets default parameters for `metricbeat` based on the OS and other facts.

#### Class: `metricbeat::repo`

Installs the yum or apt repository for the system package manager to install metricbeat.

#### Class: `metricbeat::service`

Configures and manages the metricbeat service.

#### Class: `metricbeat::install::linux`

Install the metricbeat package on Linux kernels.

#### Class: `metricbeat::install::windows`

Downloads, extracts, and installs the metricbeat zip file in Windows.

### Public Defines

#### Define: `metricbeat::input`

Installs a configuration file for a input.

Be sure to read the [metricbeat configuration details](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-configuration-details.html)
to fully understand what these parameters do.

**Parameters for `metricbeat::input`**
  - `ensure`: The ensure parameter on the input configuration file. (default: present)
  - `paths`: [Array] The paths, or blobs that should be handled by the input. (required if input_type is _log_)
  - `containers_ids`: [Array] If input_type is _docker_, the list of Docker container ids to read the logs from. (default: '*')
  - `containers_path`: [String] If input_type is _docker_, the path from where the logs should be read from. (default: /var/log/docker/containers)
  - `containers_stream`: [String] If input_type is _docker_, read from the specified stream only. (default: all)
  - `combine_partial`: [Boolean] If input_type is _docker_, enable partial messages joining. (default: false)
  - `cri_parse_flags`: [Boolean] If input_type is _docker_, enable CRI flags parsing from the log file. (default: false)
  - `syslog_protocol`: [Enum tcp,udp] Syslog protocol (default: udp)
  - `syslog_host`: [String] Host to listen for syslog messages (default: localhost:5140)
  - `exclude_files`: [Array] Files that match any regex in the list are excluded from metricbeat (default: [])
  - `encoding`: [String] The file encoding. (default: plain)
  - `input_type`: [String] where metricbeat reads the log from (default:log)
  - `fields`: [Hash] Optional fields to add information to the output (default: {})
  - `fields_under_root`: [Boolean] Should the `fields` parameter fields be stored at the top level of indexed documents.
  - `ignore_older`: [String] Files older than this field will be ignored by metricbeat (default: ignore nothing)
  - `close_older`: [String] Files that haven't been modified since `close_older`, they'll be closed. New
  modifications will be read when files are scanned again according to `scan_frequency`. (default: 1h)
  - `log_type`: [String] \(Deprecated - use `doc_type`\) The document_type setting (optional - default: log)
  - `doc_type`: [String] The event type to used for published lines, used as type field in logstash
    and elasticsearch (optional - default: log)
  - `scan_frequency`: [String] How often should the input check for new files (default: 10s)
  - `harvester_buffer_size`: [Integer] The buffer size the harvester uses when fetching the file (default: 16384)
  - `tail_files`: [Boolean] If true, metricbeat starts reading new files at the end instead of the beginning (default: false)
  - `backoff`: [String] How long metricbeat should wait between scanning a file after reaching EOF (default: 1s)
  - `max_backoff`: [String] The maximum wait time to scan a file for new lines to ship (default: 10s)
  - `backoff_factor`: [Integer] `backoff` is multiplied by this parameter until `max_backoff` is reached to
    determine the actual backoff (default: 2)
  - `force_close_files`: [Boolean] Should metricbeat forcibly close a file when renamed (default: false)
  - `pipeline`: [String] metricbeat can be configured for a different ingest pipeline for each input (default: undef)
  - `include_lines`: [Array] A list of regular expressions to match the lines that you want to include.
    Ignored if empty (default: [])
  - `exclude_lines`: [Array] A list of regular expressions to match the files that you want to exclude.
    Ignored if empty (default: [])
  - `max_bytes`: [Integer] The maximum number of bytes that a single log message can have (default: 10485760)
  - `tags`: [Array] A list of tags to send along with the log data.
  - `json`: [Hash] Options that control how metricbeat handles decoding of log messages in JSON format
    [See above](#json-logs). (default: {})
  - `multiline`: [Hash] Options that control how metricbeat handles log messages that span multiple lines.
    [See above](#multiline-logs). (default: {})

## Limitations
This module doesn't load the [elasticsearch index template](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-getting-started.html#metricbeat-template) into elasticsearch (required when shipping
directly to elasticsearch).

When installing on Windows, there's an expectation that `C:\Temp` already exists, or an alternative
location specified in the `tmp_dir` parameter exists and is writable by puppet. The temp directory
is used to store the downloaded installer only.

### Generic template

By default, a generic, open ended template is used that simply converts your configuration into
a hash that is produced as YAML on the system. To use a template that is more strict, but possibly
incomplete, set `conf_template` to `metricbeat/metricbeat.yml.erb`.

### Debian Systems

metricbeat 5.x and newer requires apt-transport-https, but this module won't install it for you.

### Using config_file
There are a few very specific use cases where you don't want this module to directly manage the metricbeat
configuration file, but you still want the configuration file on the system at a different location.
Setting `config_file` will write the metricbeat configuration file to an alternate location, but it will not
update the init script. If you don't also manage the correct file (/etc/metricbeat/metricbeat.yml on Linux,
C:/Program Files/metricbeat/metricbeat.yml on Windows) then metricbeat won't be able to start.

If you're copying the alternate config file location into the real location you'll need to include some
metaparameters like
```puppet
file { '/etc/metricbeat/metricbeat.yml':
  ensure  => file,
  source  => 'file:///etc/metricbeat/metricbeat.special',
  require => File['metricbeat.yml'],
  notify  => Service['metricbeat'],
}
```
to ensure that services are managed like you might expect.

### Logging on systems with Systemd and with version metricbeat 7.0+ installed
With metricbeat version 7+ running on systems with systemd, the metricbeat systemd service file contains a default that will ignore the logging hash parameter

```
Environment="BEAT_LOG_OPTS=-e`
```
to overide this default, you will need to set the systemd_beat_log_opts_override parameter to empty string

example:
```puppet
class {'metricbeat':
  logging => {
    'level'     => 'debug',
    'to_syslog' => false,
    'to_files'  => true,
    'files'     => {
      'path'        => '/var/log/metricbeat',
      'name'        => 'metricbeat',
      'keepfiles'   => '7',
      'permissions' => '0644'
    },
  systemd_beat_log_opts_override => "",
}
```

this will only work on systems with puppet version 6.1+. On systems with puppet version < 6.1 you will need to `systemctl daemon-reload`. This can be achived by using the [camptocamp-systemd](https://forge.puppet.com/camptocamp/systemd)

```puppet
include systemd::systemctl::daemon_reload

class {'metricbeat':
  logging => {
...
    },
  systemd_beat_log_opts_override => "",
  notify  => Class['systemd::systemctl::daemon_reload'],
}
```

## Development

Pull requests and bug reports are welcome. If you're sending a pull request, please consider
writing tests if applicable.
