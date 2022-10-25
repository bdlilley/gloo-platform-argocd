# gloo-platform-argocd

Repo will contain different use cases deployable with single argocd values file-per-usecase.

Only requirement is a cluster without argocd installed.  Some lightweight magic happens in cluster-app-of-apps/templates/app.yaml to avoid duplicating configurations; the magic detects GME or istio charts and injects some of the required version values from the argocd app value inputs.

Currently the only use case create is GME with self-managed istio.

```bash
export ISTIO_MINOR="1-14"
export ISTIO_VERSION="1.14.4"
export ISTIO_TAG="1.14.4-solo"
# see https://support.solo.io/hc/en-us/articles/4414409064596
export ISTIO_REPO="us-docker.pkg.dev/gloo-mesh/istio-dd73a086ac13"
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
        istioRepo: "${ISTIO_REPO}"
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


testing
```bash

kubectl apply -f- <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: gateways
  namespace: gloo-mesh
spec:
  workloadClusters:
  - name: cluster1
    namespaces:
    - name: istio-ingress
EOF


kubectl apply -f- <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: gateways
  namespace: istio-ingress
spec:
  importFrom:
  - workspaces:
    - selector:
        allow_ingress: "true"
    resources:
    - kind: SERVICE
    - kind: ALL
      labels:
        expose: "true"
  exportTo:
  - workspaces:
    - selector:
        allow_ingress: "true"
    resources:
    - kind: SERVICE
EOF

kubectl apply -f- <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: bookinfo
  namespace: gloo-mesh
  labels:
    allow_ingress: "true"
spec:
  workloadClusters:
  - name: cluster1
    namespaces:
    - name: bookinfo
EOF


kubectl apply -f- <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: bookinfo
  namespace: bookinfo
spec:
  importFrom:
  - workspaces:
    - name: gateways
    resources:
    - kind: SERVICE
  exportTo:
  - workspaces:
    - name: gateways
    resources:
    - kind: SERVICE
      labels:
        app: productpage
    - kind: SERVICE
      labels:
        app: reviews
    - kind: ALL
      labels:
        expose: "true"
EOF


kubectl apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  name: ns-gw
  namespace: istio-ingress
spec:
  workloads:
    - selector:
        labels:
          istio: ingressgateway
        cluster: cluster1
  listeners: 
    - http: {}
      port:
        number: 80
      allowedRouteTables:
        - host: '*'
EOF


kubectl apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: productpage
  namespace: bookinfo
  labels:
    expose: "true"
spec:
  hosts:
    - '*'
  virtualGateways:
    - name: ns-gw
      namespace: istio-ingress
      cluster: cluster1
  workloadSelectors: []
  http:
    - name: productpage
      matchers:
      - uri:
          exact: /productpage
      - uri:
          prefix: /static
      - uri:
          exact: /login
      - uri:
          exact: /logout
      - uri:
          prefix: /api/v1/products
      forwardTo:
        destinations:
          - ref:
              name: productpage
              namespace: bookinfo
            port:
              number: 9080
EOF


```