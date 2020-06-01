require 'facter'
Facter.add('metricbeat_version') do
  confine 'kernel' => ['FreeBSD', 'OpenBSD', 'Linux', 'Windows']
  if File.executable?('/usr/bin/metricbeat')
    metricbeat_version = Facter::Util::Resolution.exec('/usr/bin/metricbeat version')
    if metricbeat_version.empty?
      metricbeat_version = Facter::Util::Resolution.exec('/usr/bin/metricbeat --version')
    end
  elsif File.executable?('/usr/local/bin/metricbeat')
    metricbeat_version = Facter::Util::Resolution.exec('/usr/local/bin/metricbeat version')
    if metricbeat_version.empty?
      metricbeat_version = Facter::Util::Resolution.exec('/usr/local/bin/metricbeat --version')
    end
  elsif File.executable?('/usr/share/metricbeat/bin/metricbeat')
    metricbeat_version = Facter::Util::Resolution.exec('/usr/share/metricbeat/bin/metricbeat --version')
  elsif File.executable?('/usr/local/sbin/metricbeat')
    metricbeat_version = Facter::Util::Resolution.exec('/usr/local/sbin/metricbeat --version')
  elsif File.exist?('c:\Program Files\Metricbeat\metricbeat.exe')
    metricbeat_version = Facter::Util::Resolution.exec('"c:\Program Files\Metricbeat\metricbeat.exe" version')
    if metricbeat_version.empty?
      metricbeat_version = Facter::Util::Resolution.exec('"c:\Program Files\Metricbeat\metricbeat.exe" --version')
    end
  end
  setcode do
    metricbeat_version.nil? ? false : %r{^metricbeat version ([^\s]+)?}.match(metricbeat_version)[1]
  end
end
