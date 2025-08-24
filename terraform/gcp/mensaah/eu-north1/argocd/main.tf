data "google_client_config" "provider" {}

locals {
  # Remove map keys from all_repositories with no value. That means they were not specified
  clean_repositories = {
    for name, repo in var.repositories : name => merge({
      for k, v in repo : k => v if v != null
    }, { "name" = name })
  }

  clean_repo_templates = {
    for name, repo in var.repo_credential_templates : name => {
      for k, v in repo : k => v if v != null
    }
  }

  # If no_auth_config has been specified, set all configs as null
  values = merge({
    global = {
      domain = var.argocd_url
      image = {
        tag = var.image_tag
      }
      networkPolicy = {
        create = true
      }
    }

    server = {
      autoscaling = {
        enabled = true
      }
      pdb = {
        enabled      = true
        minAvailable = 1
      }
    }

    controller = {
      autoscaling = {
        enabled = true
      }
      pdb = {
        enabled      = true
        minAvailable = 1
      }
    }

    applicationSet = {
      autoscaling = {
        enabled = true
      }
      pdb = {
        enabled      = true
        minAvailable = 1
      }
    }

    repoServer = {
      autoscaling = {
        enabled = true
      }
      pdb = {
        enabled      = true
        minAvailable = 1
      }
    }

    configs = {
      # Configmaps require strings, yamlencode the map
      repositories        = local.clean_repositories
      credentialTemplates = local.clean_repo_templates
      cm = merge({
        "accounts.ci"         = "apiKey"
        "accounts.ci.enabled" = "true"
      }, var.config)
      rbac = {
        "policy.csv" = <<EOF
          # Grants CI deployment service read and sync permissions, generating MR diffs
          g, ci, role:readonly
          p, ci, applications, sync, */*, allow
          p, ci, applications, update, */*, allow
          # applicationsets permission is used by kubechecks to get the list of apps.
          p, ci, applicationsets, get, */*, allow

          ${var.rbac_config}
        EOF
      }

      secret = {
        extra = {
          GITHUB_TOKEN = var.repo_credential_templates.mensaah-github.password
        }
      }
    }
  })


  app_manifest = templatefile("${path.module}/manifests/app.yaml.tpl", {
    cluster_name = var.cluster.name
  })
}

# ArgoCD Charts
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  # force_update = true
  # dependency_update = true

  values = [
    file("${path.module}/helm/values.yaml"),
    yamlencode(local.values),
    yamlencode(var.values),
  ]
}

resource "kubectl_manifest" "app_manifest" {
  yaml_body = local.app_manifest

  depends_on = [helm_release.argocd]
}