#
#
#
Vagrant.configure("2") do |config|

  ###################################################################################
  # define number of controlplane nodes
  C = 3

  # provision C VMs as controlplane nodes
  (1..C).each do |i|

    # name the VM
    config.vm.define "talos-controlplane-0#{i}" do |node|

      # disable synced folders
      node.vm.synced_folder ".", "/vagrant", disabled: true

      # sizing of the VMs
      node.vm.provider "libvirt" do |lv|
        lv.random_hostname = false
        lv.memory = 2048
        lv.cpus = 2
        lv.serial :type => "file", :source => {:path => "/tmp/talos-controlplane-0#{i}.log"}
        lv.storage :file, :device => :cdrom, :path => "/tmp/talos-amd64.iso"
        lv.storage :file, :size => '4G', :type => 'raw'
        lv.boot 'hd'
        lv.boot 'cdrom'
      end

      # set the hostname
      node.vm.hostname = "talos-controlplane-0#{i}"

    end # config.vm.define controlplane nodes

  end # loop for controlplane nodes

  ###################################################################################
  # define number of controlplane nodes
  W = 1

  # provision W VMs as controlplane nodes
  (1..W).each do |i|

    config.vm.define "talos-worker-0#{i}" do |node|
      node.vm.provider "libvirt" do |lv|
        lv.random_hostname = false
        lv.memory = 1024
        lv.cpus = 1
        lv.serial :type => "file", :source => {:path => "/tmp/talos-worker-0#{i}.log"}
        lv.storage :file, :device => :cdrom, :path => "/tmp/talos-amd64.iso"
        lv.storage :file, :size => '4G', :type => 'raw'
        lv.boot 'hd'
        lv.boot 'cdrom'
      end # libvirt

      # set the hostname
      node.vm.hostname = "talos-worker-0#{i}"

    end # config.vm.define

  end # loop for worker nodes

end # Vagrant.configure
