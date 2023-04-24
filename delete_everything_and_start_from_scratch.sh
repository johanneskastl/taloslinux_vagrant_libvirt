#!/bin/bash

for file in \
    .configuration_applied_on_first_node \
    .configuration_applied_to_all_nodes \
    controlplane.yaml \
    .first_node_bootstrapped \
    kubeconfig \
    talosconfig \
    .user_supplied_virtual_ip \
    worker.yaml
do
    echo "Removing ${file}"
    rm -vf "${file}" || exit 9
done
