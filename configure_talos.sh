#!/bin/bash

get_ip() {
    virsh domifaddr "$1" | awk '/ipv4/ {print $4}' | awk -F'/' '{print $1}'
}

IP_CONTROLPLANE_01="$(get_ip taloslinux_vagrant_libvirt_talos-controlplane-01)"
IP_CONTROLPLANE_02="$(get_ip taloslinux_vagrant_libvirt_talos-controlplane-02)"
IP_CONTROLPLANE_03="$(get_ip taloslinux_vagrant_libvirt_talos-controlplane-03)"
IP_WORKER_01="$(get_ip taloslinux_vagrant_libvirt_talos-worker-01)"

[ -z "${IP_CONTROLPLANE_01}" ] && {
    echo "IP of controlplane-01 not set, aborting..."
    exit 3
}

[ -z "${IP_CONTROLPLANE_02}" ] && {
    echo "IP of controlplane-02 not set, aborting..."
    exit 3
}

[ -z "${IP_CONTROLPLANE_03}" ] && {
    echo "IP of controlplane-03 not set, aborting..."
    exit 3
}

[ -z "${IP_WORKER_01}" ] && {
    echo "IP of worker-01 not set, aborting..."
    exit 3
}

echo "IP of controlplane-01 is ${IP_CONTROLPLANE_01}"
echo "IP of controlplane-02 is ${IP_CONTROLPLANE_02}"
echo "IP of controlplane-03 is ${IP_CONTROLPLANE_03}"
echo "IP of worker-01 is ${IP_WORKER_01}"

##################################################################
#
#
read -p "Please provide a free IP in the same range to use as a virtual IP (or type 'q' to quit):" -r
echo

[[ "$REPLY" == "q" ]] && {
    echo "User decided to quit"
    exit 0
}

[[ -z "$REPLY" ]] && {
    echo "No IP address provided, aborting"
    exit 3
}

VALID_IP_REGEX='(^([1-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5]))$'
if [[ "$REPLY" =~ $VALID_IP_REGEX ]]
then
    VIRTUAL_IP="$REPLY"
else
    echo "$REPLY does not look like a valid IP address..."
fi

##################################################################
#
#
echo "Generating config"
[[ -e controlplane.yaml ]] || talosctl gen config talos_vagrant_libvirt https://"${VIRTUAL_IP}":6443 --install-disk /dev/vda || exit 7

[[ -e worker.yaml ]]  || {
    echo "worker.yaml does not exist, aborting"
    exit 11
}

[[ -e controlplane.yaml ]]  || {
    echo "controlplane.yaml does not exist, aborting"
    exit 13
}

[[ -e talosconfig ]]  || {
    echo "talosconfig does not exist, aborting"
    exit 13
}

# add interface with vip to controlplane.yml
grep -q "ip: ${VIRTUAL_IP}" controlplane.yaml || (patch controlplane.yaml < controlplane.yaml.patch || exit 9)

grep -q "ip: ${VIRTUAL_IP}" controlplane.yaml || {
    echo "Patching was not successful, aborting"
    exit 7
}

##################################################################
#
#
if [[ -e .configuration_applied_on_first_node ]]
then
    echo "Configuration was already applied to first node"
else
    echo "Apply configuration to first node"
    talosctl -n "${IP_CONTROLPLANE_01}" apply-config --insecure --file controlplane.yaml || exit 21
    touch .configuration_applied_on_first_node
    echo "Configuration applied..."
    echo "Sleeping 100s"
    sleep 100
fi

##################################################################
#
#
TALOSCONFIG=$(realpath ./talosconfig)
export TALOSCONFIG
talosctl config endpoint "${IP_CONTROLPLANE_01}" "${IP_CONTROLPLANE_02}" "${IP_CONTROLPLANE_03}"

echo "Bootstrapping first node"
if [[ -e .first_node_bootstrapped ]]
then
    echo "Bootstrapping was already done..."
else
    talosctl -n "${IP_CONTROLPLANE_01}" bootstrap || exit 23
    touch .first_node_bootstrapped
    echo "Bootstrapping successful"
    echo "Sleeping 100s"
    sleep 100
fi

##################################################################
#
#
if [[ -e .configuration_applied_to_all_nodes ]]
then
    echo "Configure other nodes"
    talosctl -n "${IP_CONTROLPLANE_02}" apply-config --insecure --file controlplane.yaml || exit 31
    talosctl -n "${IP_CONTROLPLANE_03}" apply-config --insecure --file controlplane.yaml || exit 33
    talosctl -n "${IP_WORKER_01}" apply-config --insecure --file worker.yaml || exit 35
    touch .configuration_applied_to_all_nodes
    echo "Sleeping 300s"
    sleep 300
fi

talosctl -n "${VIRTUAL_IP}" kubeconfig ./kubeconfig || exit 41

kubectl --kubeconfig ./kubeconfig get nodes -w

exit 0
