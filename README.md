# gloo-platform-argocd

A repo that uses the ArgoCD app of apps pattern to deploy Solo product use cases.

# install argocd core

This is the light verison, some components are not installed in cluster (like sso, rbac, and ui).  You can still access a UI using the argocd cli.

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml
# defect in argocd cli - the context ns must be argocd to use the admin dashboard command
kubectl config set-context --current --namespace=argocd
argocd admin dashboard &
open http://localhost:8080
```



# create an argocd app of apps stack based on use case

First set HZ ID to be used by external-dns; this depends on your account and setup - look at https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones# in console.

```bash
export PRIVATE_HZ_ID="Z08503781ORNZIT2J3JF7"
```

```bash

export CLUSTER_NAME="ben"
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
    targetRevision: main
    path: argocd-aoa
    helm:
      valueFiles:
      - values-infrastructure-core.yaml
      - values-ben.yaml
      values: |
        global:
          istio-ingressgateway:
            serviceAccount:
              annotations:
                eks.amazonaws.com/role-arn: arn:aws:iam::931713665590:role/${CLUSTER_NAME}-gloo-gateway-proxy
          aws-load-balancer-controller:
            clusterName: ${CLUSTER_NAME}
          external-dns:
            txtOwnerId: ${PRIVATE_HZ_ID}
            txtPrefix: ${CLUSTER_NAME}
          external-secrets:
            serviceAccount:
              create: true
              name: external-secrets
              annotations:
                eks.amazonaws.com/role-arn: arn:aws:iam::931713665590:role/${CLUSTER_NAME}-gloo-secrets-sync
          gloo-mesh-enterprise:
            glooMeshMgmtServer:
              serviceAccount:
                extraAnnotations:
                  eks.amazonaws.com/role-arn: arn:aws:iam::931713665590:role/${CLUSTER_NAME}-gloo-discovery
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
EOF




export CLUSTER_NAME="ge-single"
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
    targetRevision: main
    path: argocd-aoa
    helm:
      valueFiles:
      - values-infrastructure-core.yaml
      - values-ge-single.yaml
      values: |
        global:
          aws-load-balancer-controller:
            clusterName: ${CLUSTER_NAME}
          external-dns:
            txtOwnerId: ${PRIVATE_HZ_ID}
          gloo-edge:
            gloo:
              gateway:
                proxyServiceAccount:
                  extraAnnotations:
                    eks.amazonaws.com/role-arn: arn:aws:iam::931713665590:role/${CLUSTER_NAME}-gloo-gateway-proxy
              discovery:
                serviceAccount:
                  extraAnnotations:
                    eks.amazonaws.com/role-arn: arn:aws:iam::931713665590:role/${CLUSTER_NAME}-gloo-discovery
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
EOF



export CLUSTER_NAME="gg-single"
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
    targetRevision: main
    path: argocd-aoa
    helm:
      valueFiles:
      - values-infrastructure-core.yaml
      - values-gm-single.yaml
      values: |
        global:
          istio-ingressgateway:
            serviceAccount:
              annotations:
                eks.amazonaws.com/role-arn: arn:aws:iam::931713665590:role/${CLUSTER_NAME}-gloo-gateway-proxy
          aws-load-balancer-controller:
            clusterName: ${CLUSTER_NAME}
          external-dns:
            txtOwnerId: ${PRIVATE_HZ_ID}
            txtPrefix: ${CLUSTER_NAME}
          gloo-mesh:
            gloo:
              gateway:
                proxyServiceAccount:
                  extraAnnotations:
                    eks.amazonaws.com/role-arn: arn:aws:iam::931713665590:role/${CLUSTER_NAME}-gloo-gateway-proxy
              discovery:
                serviceAccount:
                  extraAnnotations:
                    eks.amazonaws.com/role-arn: arn:aws:iam::931713665590:role/${CLUSTER_NAME}-gloo-discovery
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
EOF

```



---

### old stuff


# create gloo license secret

_mesh_
```bash
kubectl create ns gloo-mesh 
kubectl apply -f - <<EOF
apiVersion: v1
data:
  gloo-gateway-license-key: $(echo -n "${LICENSE_KEY}" | base64)
  gloo-mesh-license-key: $(echo -n "${LICENSE_KEY}" | base64)
  gloo-mesh-enterprise-license-key: $(echo -n "${LICENSE_KEY}" | base64)
kind: Secret
metadata:
  name: gloo-mesh-license
  namespace: gloo-mesh
type: Opaque
EOF
```

_edge_
```bash
kubectl create ns gloo-system 
kubectl apply -f - <<EOF
apiVersion: v1
data:
  license-key: $(echo -n "${GLOO_EDGE_LICENSE_KEY}" | base64)
kind: Secret
metadata:
  name: gloo-edge-license
  namespace: gloo-system
type: Opaque
EOF
```