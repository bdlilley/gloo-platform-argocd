
tmp=$(mktemp)

cat <<EOF > "$tmp"
global:
  cluster: cluster1
registerMgmtPlane:
  enabled: true
  managedInstallations:
    controlPlane:
      enabled: true
      overrides: {}
    defaultRevision: true
    enabled: true
    images:
      hub: us-docker.pkg.dev/gloo-mesh/istio-1cf99a48c9d8
      tag: 1.15.1-solo
    northSouthGateways:
    - enabled: true
      name: istio-ingressgateway
      overrides: {}
    revision: 1-15
EOF


kubectl create ns gloo-mesh
meshctl install --namespace gloo-mesh --license $GLOO_GATEWAY_LICENSE_KEY --chart-values-file "${tmp}"

kubectl create ns bookinfo
kubectl -n bookinfo apply -f "https://raw.githubusercontent.com/istio/istio/1.15.1/samples/bookinfo/platform/kube/bookinfo.yaml" -l 'app'
kubectl -n bookinfo apply -f "https://raw.githubusercontent.com/istio/istio/1.15.1/samples/bookinfo/platform/kube/bookinfo.yaml" -l 'account'