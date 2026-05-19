apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-registry
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mensaah/infras-setup.git
    targetRevision: HEAD
    path: kubernetes/registry/${cluster_name}
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd

  # Sync policy
  syncPolicy:
    automated:
      prune: false
      selfHeal: true