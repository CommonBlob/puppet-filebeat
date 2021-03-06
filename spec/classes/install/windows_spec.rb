require 'spec_helper'

describe 'metricbeat::install::windows' do
  let :pre_condition do
    'include ::metricbeat'
  end

  on_supported_os(facterversion: '2.4').each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      case facts[:kernel]
      when 'windows'
        # it { is_expected.to compile }
        it { is_expected.to contain_file('C:/Program Files').with_ensure('directory') }
        # it {
        #   is_expected.to contain_archive('C:/Windows/Temp/metricbeat-5.6.2-windows-x86_64.zip').with(
        #     creates: 'C:/Program Files/Metricbeat/metricbeat-5.6.2-windows-x86_64',
        #   )
        # }
        # it {
        #   is_expected.to contain_exec('install metricbeat-5.6.2-windows-x86_64').with(
        #     command: './install-service-metricbeat.ps1',
        #   )
        # }
        # it {
        #   is_expected.to contain_exec('unzip metricbeat-5.6.2-windows-x86_64').with(
        #     command: '$sh=New-Object -COM Shell.Application;$sh.namespace((Convert-Path \'C:/Program Files\')).'\
        #              'Copyhere($sh.namespace((Convert-Path \'C:/Windows/Temp/metricbeat-5.6.2-windows-x86_64.zip\')).items(), 16)',
        #   )
        # }
        # it {
        #   is_expected.to contain_exec('mark metricbeat-5.6.2-windows-x86_64').with(
        #     command: 'New-Item \'C:/Program Files/Metricbeat/metricbeat-5.6.2-windows-x86_64\' -ItemType file',
        #   )
        # }
        # it {
        #   is_expected.to contain_exec('rename metricbeat-5.6.2-windows-x86_64').with(
        #     command: 'Remove-Item \'C:/Program Files/Metricbeat\' -Recurse -Force -ErrorAction SilentlyContinue;'\
        #              'Rename-Item \'C:/Program Files/metricbeat-5.6.2-windows-x86_64\' \'C:/Program Files/Metricbeat\'',
        #   )
        # }
        # it {
        #   is_expected.to contain_exec('stop service metricbeat-5.6.2-windows-x86_64').with(
        #     command: 'Set-Service -Name metricbeat -Status Stopped',
        #   )
        # }
        # it {
        #   is_expected.to contain_file('C:/Windows/Temp/metricbeat-5.6.2-windows-x86_64.zip').with(
        #     ensure: 'absent',
        #   )
        # }
      else
        it { is_expected.not_to compile }
      end
    end
  end
end
