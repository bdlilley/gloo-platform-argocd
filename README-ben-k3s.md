
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
    repoURL: https://github.com/bensolo-io/gloo-platform-argocd.git
    targetRevision: main
    path: argocd-aoa
    helm:
      valueFiles:
      - values-k3s.yaml
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
EOF