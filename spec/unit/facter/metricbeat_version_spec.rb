require 'spec_helper'

describe 'metricbeat_version' do
  before :each do
    Facter.clear
    Facter.fact(:kernel).stubs(:value).returns('Linux')
  end
  context 'when on a Linux host' do
    before :each do
      File.stubs(:executable?)
      Facter::Util::Resolution.stubs(:exec)
      File.expects(:executable?).with('/usr/share/metricbeat/bin/metricbeat').returns true
      Facter::Util::Resolution.stubs(:exec).with('/usr/share/metricbeat/bin/metricbeat --version').returns('metricbeat version 5.1.1 (amd64), libbeat 5.1.1')
    end
    it 'returns the correct version' do
      expect(Facter.fact(:metricbeat_version).value).to eq('5.1.1')
    end
  end

  context 'when the metricbeat package is not installed' do
    before :each do
      File.stubs(:executable?)
      Facter::Util::Resolution.stubs(:exec)
      File.expects(:executable?).with('/usr/bin/metricbeat').returns false
      File.expects(:executable?).with('/usr/local/bin/metricbeat').returns false
      File.expects(:executable?).with('/usr/share/metricbeat/bin/metricbeat').returns false
      File.expects(:executable?).with('/usr/local/sbin/metricbeat').returns false
      File.stubs(:exist?)
      File.expects(:exist?).with('c:\Program Files\Metricbeat\metricbeat.exe').returns false
    end
    it 'returns false' do
      expect(Facter.fact(:metricbeat_version).value).to eq(false)
    end
  end
end
