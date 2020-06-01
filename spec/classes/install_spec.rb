require 'spec_helper'

describe 'metricbeat::install' do
  let :pre_condition do
    'include ::metricbeat'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      if os_facts[:kernel] != 'windows'
        it { is_expected.to compile }
      end

      it { is_expected.to contain_anchor('metricbeat::install::begin') }
      it { is_expected.to contain_anchor('metricbeat::install::end') }

      case os_facts[:kernel]
      when 'Linux'
        it { is_expected.to contain_class('metricbeat::install::linux') }
        it { is_expected.to contain_class('metricbeat::repo') } unless os_facts[:os]['family'] == 'Archlinux'
        it { is_expected.not_to contain_class('metricbeat::install::windows') }

      when 'Windows'
        it { is_expected.to contain_class('metricbeat::install::windows') }
        it { is_expected.not_to contain_class('metricbeat::install::linux') }
      end
    end
  end
end
