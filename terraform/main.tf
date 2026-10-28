terraform {
  required_version = ">= 1.15.0"
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "~> 3.2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

variable "fqdn" {
  type = string

  validation {
    condition = length(split(".", var.fqdn)) >= 3
    error_message = "fqdn must look like host.domain.tld."
  }
}

variable "mqtts_ingress_ip" {
  type = string

  validation {
    condition = can(cidrhost("${var.ip_address}/32", 0))
    error_message = "mqtts_ingress_ip must be a valid IPv4 address, e.g. 192.168.1.10."
  }
}

variable "mqtts_ingress_ip_share" {
  type = string
  default = null
  nullable = true
}

locals {
  fqdn = trimspace(var.fqdn)
  ip = trimspace(var.mqtts_ingress_ip)
  ip_share = trimspace(var.mqtts_ingress_ip_share)
  _fqdn_split = split(".", local.fqdn)
  hostname = local._fqdn_split[0]
  domain = join(".", slice(local._fqdn_split, 1, length(local._fqdn_split)))
}

resource "kubernetes_manifest" "vernemq_wildcard_cert" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind = "Certificate"
    metadata = {
      name = local.domain
      namespace = "vernemq"
    }
    spec = {
      secretName = local.domain
      dnsNames = ["*.${local.domain}", "${local.domain}"]
      privateKey = {
        algorithm = "RSA"
        size = 4096
      }
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
    }
  }
}

resource "helm_release" "vernemq" {
  name = "vernemq"
  repository = "oci://ghcr.io/11notes/charts"
  chart = "vernemq"
  namespace = "vernemq"
  version = "0.0.1"

  wait = true
  wait_for_jobs = true

  values = [
    yamlencode({
      secretMounts = {
        name = local.domain
        secretName = local.domain
      }
    })
  ]
}

resource "kubernetes_service_v1" "vernemq_ingress_mqtts" {
  metadata {
    name = "vernemq-ingress-mqtts"
    namespace = "vernemq"
    annotations = merge(
      {
        "metallb.io/loadBalancerIPs" = local.ip
      },
      local.ip_share != null ? {
        "metallb.io/allow-shared-ip" = local.ip_share
      } : {}
    )
  }
  spec {
    type = "LoadBalancer"
    external_traffic_policy = "Local"
    selector = {
      "app.kubernetes.io/instance" = "vernemq"
      "app.kubernetes.io/name" = "vernemq"
    }
    port {
      name = "vernemq-mqtts"
      protocol = "TCP"
      port = 8883
      target_port = 8883
    }
  }
}

resource "kubernetes_ingress_v1" "vernemq_ingress_ui" {
  metadata {
    name = "vernemq-ingress"
    namespace = "vernemq"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }

  spec {
    ingress_class_name = "traefik"

    tls {
      hosts = [local.fqdn]
      secret_name = local.domain
    }

    rule {
      host = local.fqdn
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "vernemq"
              port {
                number = 8888
              }
            }
          }
        }
      }
    }
  }
}