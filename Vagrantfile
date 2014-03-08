# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Vagrantfile for deploying SaltStack master servers to Virtualbox and
# Digital Ocean droplets.


MASTER_HOSTNAME = "mr-beagle"
SALTLICK_PATH = ""

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # NB: Saucy seems to be having sync_folder issues on Mavericks, circa Jan 2014
  #config.vm.box = "saucy64"
  #config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/saucy/current/" +
  #                    "saucy-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.box = "raring64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/current/" +
                      "raring-server-cloudimg-amd64-vagrant-disk1.box"
 
  config.ssh.forward_agent = true

  config.vm.network "private_network", ip: "192.168.30.30"
  config.vm.network :forwarded_port,
    guest: 22, host: 2230, id: "ssh", auto_correct: true
  config.vm.network :forwarded_port, protocol: 'udp',
    guest: 62230, host: 62230, id: "mosh", auto_correct: true

  config.vm.define MASTER_HOSTNAME do |host|
  end

  config.vm.provider :virtualbox do |vb|
      vb.name = MASTER_HOSTNAME
  end

  config.vm.hostname = MASTER_HOSTNAME

  #config.vm.synced_folder SALTLICK_PATH + "srv/", "/srv/"
  #config.vm.synced_folder SALTLICK_PATH + "srv/salt/", "/srv/salt/"
  #config.vm.synced_folder SALTLICK_PATH + "srv/pillar/", "/srv/pillar/"
  config.vm.synced_folder ".", "/vagrant", id: "vagrant-root", disabled: true
  config.vm.synced_folder SALTLICK_PATH, "/srv/formulas/saltlick-formula"

  $bootstrapper = <<-SCRIPT
    mkdir -p /srv/salt/formulas
    ln -s /srv/formulas/saltlick-formula/saltlick /srv/salt/saltlick
    ln -s /srv/formulas/saltlick-formula/etc/top.sls /srv/salt/top.sls
    mkdir -p /etc/salt
    cp /srv/formulas/saltlick-formula/etc/minion /etc/salt/
  SCRIPT
  config.vm.provision "shell", inline: $bootstrapper

  #command = "cp #{File.join('/vagrant/', path_within_repo)} #{remote_file}"
  #config.vm.provision :shell, :inline => command 



  # SaltStack master setup (with its own local minion)
  config.vm.provision :salt do |salt|

    # TODO: See if we can drop the minion setup in $bootstrapper above
    salt.minion_config = SALTLICK_PATH + "etc/minion"

    salt.no_minion = false
    salt.minion_key = SALTLICK_PATH + "etc/keys/minion.pem"
    salt.minion_pub = SALTLICK_PATH + "etc/keys/minion.pub"
    salt.seed_master = {MASTER_HOSTNAME => salt.minion_pub}

    salt.install_master = true
    salt.master_key = SALTLICK_PATH + "etc/keys/master.pem"
    salt.master_pub = SALTLICK_PATH + "etc/keys/master.pub"

    salt.install_type = "git"
    salt.install_args = "2014.1"
    #salt.install_type = "stable"

    salt.run_highstate = true
    salt.always_install = false
    salt.verbose = true
  end 



  # Run a second state.highstate after the bootstrap state has
  # checked everything out into its correct places.
  config.vm.provision "shell", inline: "sleep 5"
  config.vm.provision "shell", inline: "sudo salt " + MASTER_HOSTNAME + " state.highstate"



  # Provider: Digital Ocean
  # NB: As of January 2014, the Salt provisioning is failing when using
  # Digital Ocean as a provider, in interesting different ways for
  # different values of salt.install_type/salt/install_args.
  config.vm.provider :digital_ocean do |provider, override|
    provider.image = 'Ubuntu 13.10 x64'
    provider.region = 'Singapore 1'
    provider.size = '512MB'
    provider.private_networking = true
    provider.ssh_key_name = 'trepp-rsa'
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
