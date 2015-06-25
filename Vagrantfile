# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

$post_up_message = '** Your Vagrant box is ready to use! \o/ **
Log in (with `vagrant ssh`) and follow the instructions.'

if File.exist?('.env') && File.read('.env').include?('replace_with_')
  $post_up_message += "\n\nWARNING: Incomplete .env file detected.
Please fill it in by following the instructions in README.md."
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'ubuntu/trusty64'
  config.vm.network 'forwarded_port', guest: 5000, host: 5000
  config.vm.provision 'shell', path: 'scripts/provision.sh', privileged: false
  config.vm.synced_folder '.', '/vagrant', nfs: true
  config.vm.network :private_network, ip: '192.168.50.4'
  config.vm.post_up_message = $post_up_message
  config.vm.provider :virtualbox do |v|
    v.memory = 1024
  end
end
