require 'spec_helper'

describe 'metricbeat' do
  let :pre_condition do
    'include ::metricbeat'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      if os_facts[:kernel] != 'windows'
        it { is_expected.to compile }
      end

      it { is_expected.to contain_class('metricbeat') }
      it { is_expected.to contain_class('metricbeat::params') }
      it { is_expected.to contain_anchor('metricbeat::begin') }
      it { is_expected.to contain_anchor('metricbeat::end') }
      it { is_expected.to contain_class('metricbeat::install') }
      it { is_expected.to contain_class('metricbeat::config') }
      it { is_expected.to contain_class('metricbeat::service') }
    end
  end
end
