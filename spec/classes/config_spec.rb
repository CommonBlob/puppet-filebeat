require 'spec_helper'

describe 'metricbeat::config' do
  let :pre_condition do
    'include ::metricbeat'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { "class { 'metricbeat': major_version => '#{major_version}' }" }

      [5, 6].each do |version|
        context "with $major_version == #{version}" do
          let(:major_version) { version }

          let(:validate_cmd) do
            path = case os_facts[:os]['family']
                   when 'Archlinux'
                     '/usr/bin/metricbeat'
                   else
                     '/usr/share/metricbeat/bin/metricbeat'
                   end

            case major_version
            when 5
              "#{path} -N -configtest -c %"
            else
              "#{path} -c % test config"
            end
          end

          case os_facts[:kernel]
          when 'Linux'
            it { is_expected.to compile }
            it {
              is_expected.to contain_file('metricbeat.yml').with(
                ensure: 'file',
                path: '/etc/metricbeat/metricbeat.yml',
                owner: 'root',
                group: 'root',
                mode: '0644',
                validate_cmd: validate_cmd,
                notify: 'Service[metricbeat]',
                require: 'File[metricbeat-config-dir]',
              )
            }

            it {
              is_expected.to contain_file('metricbeat-config-dir').with(
                ensure: 'directory',
                path: '/etc/metricbeat/conf.d',
                owner: 'root',
                group: 'root',
                mode: '0755',
                recurse: true,
                purge: true,
              )
            }
          when 'Windows'
            it {
              is_expected.to contain_file('metricbeat.yml').with(
                ensure: 'file',
                path: 'C:/Program Files/Metricbeat/metricbeat.yml',
                notify: 'Service[metricbeat]',
                require: 'File[metricbeat-config-dir]',
              )
            }

            it {
              is_expected.to contain_file('metricbeat-config-dir').with(
                ensure: 'directory',
                path: 'C:/Program Files/Metricbeat/conf.d',
                recurse: true,
                purge: true,
              )
            }
          end
        end
      end
    end
  end
end
