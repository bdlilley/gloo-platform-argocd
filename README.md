# gloo-platform-argocd

Repo will contain different use cases deployable with single argocd values file-per-usecase.

Only requirement is a cluster without argocd installed.  Some lightweight magic happens in cluster-app-of-apps/templates/app.yaml to avoid duplicating configurations; the magic detects GME or istio charts and injects some of the required version values from the argocd app value inputs.

```bash
export ISTIO_MINOR="1-15"
export ISTIO_VERSION="1.15.1"
export ISTIO_TAG="1.15.1-solo"
export ISTIO_REPO="us-docker.pkg.dev/gloo-mesh/istio-1cf99a48c9d8"
export GLOO_MESH_VERSION="2.1.0-rc2"

# install argocd core only
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/core-install.yaml

# create an app of apps to install specific verisons of products
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
      - gm-single.yaml
      values: |
        glooGatewayLicenseKey: "${GLOO_GATEWAY_LICENSE_KEY}"
        glooMeshLicenseKey: "${GLOO_MESH_LICENSE_KEY}"
        glooVersion: "${GLOO_MESH_VERSION}"
        istioVersion: "${ISTIO_VERSION}"
        istioVersionLabel: "${ISTIO_MINOR}"
        istioTag: "${ISTIO_TAG}"
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
EOF

argocd admin dashboard &
open http://localhost:8080

# # not in use yet - this pattern allows using meshctl inside argocd as a plugin
# envsubst < ./argocd-install/templates/set-gloo-version.yaml > ./argocd-install/overlays/istio/set-gloo-version.yaml
# kubectl create ns argocd
# kubectl create secret generic gloo-license -n argocd --from-literal=gloo-mesh-license-key="${GLOO_MESH_LICENSE_KEY}" --from-literal=gloo-gateway-license-key="${GLOO_GATEWAY_LICENSE_KEY}"
# kubectl apply -k ./argocd-install/overlays/istio -n argocd
```