export ISTIO_MINOR="1-15"
export ISTIO="1.15.1"
export ISTIO_TAG="1.15.1-solo"
export ISTIO_REPO="us-docker.pkg.dev/gloo-mesh/istio-1cf99a48c9d8"
export GLOO_MESH_VERSION="2.1.0-rc2"

envsubst < ./argocd-install/templates/set-gloo-version.yaml > ./argocd-install/overlays/istio/set-gloo-version.yaml
kubectl create ns argocd
kubectl create secret generic gloo-license -n argocd --from-literal=gloo-mesh-license-key="${GLOO_MESH_LICENSE_KEY}" --from-literal=gloo-gateway-license-key="${GLOO_GATEWAY_LICENSE_KEY}"
kubectl apply -k ./argocd-install/overlays/istio -n argocd

cat <<EOF | kubectl apply -f -
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/bdlilley/gloo-platform-argocd.git
    targetRevision: HEAD
    path: cluster-app-of-apps
    helm:
      valueFiles:
      - gm-single-2.1.0-rc2-istio-1.15.1.yaml
      values: |
        glooGatewayLicenseKey: "${GLOO_GATEWAY_LICENSE_KEY}"
        glooMeshLicenseKey: "${GLOO_MESH_LICENSE_KEY}"
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
EOF