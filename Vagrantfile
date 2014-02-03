# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Vagrantfile for deploying SaltStack master servers to Virtualbox and
# Digital Ocean droplets.


MASTER_HOSTNAME = "missfoal"
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "raring64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/current/" +
                      "raring-server-cloudimg-amd64-vagrant-disk1.box"
  #config.vm.box = "saucy64"
  #config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/saucy/current/" +
  #                    "saucy-server-cloudimg-amd64-vagrant-disk1.box"
  config.ssh.forward_agent = true

  config.vm.network "private_network", ip: "192.168.30.30"
  config.vm.network :forwarded_port,
    guest: 22, host: 2230, id: "ssh", auto_correct: true

  config.vm.define MASTER_HOSTNAME do |foohost|
  end

  config.vm.provider :virtualbox do |vb|
      vb.name = MASTER_HOSTNAME
  end

  #config.vm.hostname = MASTER_HOSTNAME

  config.vm.synced_folder ".saltlick/srv/", "/srv/"
  #config.vm.synced_folder ".saltlick/roots/pillar/", "/srv/pillar/"

  # SaltStack master setup (with its own local minion)
  config.vm.provision :salt do |salt|

    #salt.bootstrap_script = ".saltlick/bootstrap-salt.sh"
    #salt.bootstrap_options = "-D -U -M"

    salt.minion_config = ".saltlick/minion"
    #salt.master_config = ".saltlick/master"

    salt.no_minion = false
    salt.minion_key = ".saltlick/key/minion.pem"
    salt.minion_pub = ".saltlick/key/minion.pub"
    salt.seed_master = {minion: salt.minion_pub}

    salt.install_master = true
    salt.master_key = ".saltlick/key/master.pem"
    salt.master_pub = ".saltlick/key/master.pub"

    salt.install_type = "git"
    salt.install_args = "develop"

    #salt.accept_keys = true
    salt.run_highstate = true
    salt.always_install = false
    salt.verbose = true
  end 

  # Provider: Digital Ocean
  # NB: As of January 2014, the Salt provisioning is failing when using
  # Digital Ocean as a provider, in interesting different ways for
  # different values of salt.install_type/salt/install_args.
  config.vm.provider :digital_ocean do |provider, override|
    provider.image = 'Ubuntu 13.10 x64'
    provider.region = 'New York 2'
    provider.size = '512MB'
    provider.private_networking = true
    provider.ssh_key_name = 'salty-vagrant'
    provider.backups_enabled = true
    provider.setup = false
  end

  # Now add the following to your ~/.vagrant.d/Vagrantfile after finding
  # your client ID and  API key on https://cloud.digitalocean.com/api_access:
  #
  # Vagrant.configure("2") do |config|
  #   config.vm.provider :digital_ocean do |provider, override|
  #     override.vm.box = 'digital_ocean'
  #     override.ssh.private_key_path = '~/.ssh/id_rsa'
  #     override.vm.box_url = "https://github.com/hipikat/vagrant-digitalocean/" +
  #                           "blob/master/box/digital_ocean.box?raw=true"
  #     provider.client_id = 'Your Digital Ocean client ID'
  #     provider.api_key = 'Your Digital Ocean API key'
  #   end 
  # end 

end
