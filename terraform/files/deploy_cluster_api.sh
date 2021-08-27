#!/usr/bin/env bash

##    desc: a helper for deploy a workload cluster on mgmt cluster
## license: Apache-2.0

# variables
CLUSTERAPI_OPENSTACK_PROVIDER_VERSION=0.4.0
CLUSTERAPI_VERSION=0.4.2

# get the clusterctl version
echo "show the clusterctl version:"
clusterctl version --output yaml

# set some Variables to the clusterctl.yaml
bash clusterctl_template.sh

# cp clusterctl.yaml to the right place
cp -p $HOME/clusterctl.yaml $HOME/.cluster-api/clusterctl.yaml

# deploy cluster-api on mgmt cluster
echo "deploy cluster-api with openstack provider ${CLUSTERAPI_OPENSTACK_PROVIDER_VERSION}"
clusterctl init --infrastructure openstack:v${CLUSTERAPI_OPENSTACK_PROVIDER_VERSION} --core cluster-api:v${CLUSTERAPI_VERSION} -b kubeadm:v${CLUSTERAPI_VERSION} -c kubeadm:v${CLUSTERAPI_VERSION}

# Install calicoctl
# TODO: Check signature
curl -o calicoctl -O -L  "https://github.com/projectcalico/calicoctl/releases/download/v3.20.0/calicoctl" 
chmod +x calicoctl
sudo mv calicoctl /usr/local/bin

# wait for CAPI pods
echo "# wait for all components are ready for cluster-api"
kubectl wait --for=condition=Ready --timeout=5m -n capi-system pod --all
kubectl wait --for=condition=Ready --timeout=5m -n capi-webhook-system pod --all
kubectl wait --for=condition=Ready --timeout=5m -n capi-kubeadm-bootstrap-system pod --all
kubectl wait --for=condition=Ready --timeout=5m -n capi-kubeadm-control-plane-system pod --all
kubectl wait --for=condition=Ready --timeout=5m -n capo-system pod --all

# wait for CAPO crds
kubectl wait --for condition=established --timeout=60s crds/openstackmachines.infrastructure.cluster.x-k8s.io
kubectl wait --for condition=established --timeout=60s crds/openstackmachinetemplates.infrastructure.cluster.x-k8s.io
kubectl wait --for condition=established --timeout=60s crds/openstackclusters.infrastructure.cluster.x-k8s.io

