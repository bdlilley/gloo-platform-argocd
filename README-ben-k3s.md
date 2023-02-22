
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml
# defect in argocd cli - the context ns must be argocd to use the admin dashboard command
kubectl config set-context --current --namespace=argocd
argocd admin dashboard &
open http://localhost:8080

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