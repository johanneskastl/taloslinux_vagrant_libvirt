# taloslinux_vagrant_libvirt.git

This Vagrant setup creates four VMs, three as Kubernetes controlplane nodes and
one as worker node.

It is based on the official [vagrant-libvirt
documentation](https://www.talos.dev/v1.4/talos-guides/install/virtualized-platforms/vagrant-libvirt/).

## Vagrant

1. You need vagrant and vagrant-libvirt obviously.
1. You need to download the latest `talos-amd64.iso` file from
   [the Release page](https://github.com/siderolabs/talos/releases) and place it
   in the `/tmp/` directory as `/tmp/talos-amd64.iso`.
   Checking its SHA256sum is not a bad idea!
1. You also need to have `talosctl` available, you can also download it from the
   release page.
1. Run `vagrant up`
1. Wait for the machines to boot and get an IP address, then run the
   `configure_talos.sh` script. This script
   - reads in the IP addresses
   - asks you for an IP address in the same network as the VM IPs (that is not
     in use)
   - creates a configuration file
   - bootstraps the first node
   - sleeps 60s
   - asks for confirmation to proceed
   - configures the other nodes
   - waits 180s
   - downloads the kubeconfig file to the local directory
   - shows the nodes via `kubectl get nodes`
1. Party!

## Cleaning up

When tearing down the machines, several configuration files are left behind. You
can remove all of them using the `delete_everything_and_start_from_scratch.sh`
script.
