resource "helm_release" "dex" {
  chart      = "dex"
  name       = "dex"
  repository = "https://charts.dexidp.io"
  version    = "0.14.0"
  namespace  = "dex"

  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  lint             = true
  timeout          = 120

  values = [<<YAML
envFrom:
 - secretRef:
     name: dex-github-connector
 - secretRef:
     name: dex-argocd-client
 - secretRef:
     name: dex-grafana-client
replicaCount: 2
https:
  enabled: false
ingress:
  enabled: true
  hosts:
    - host: login.klangregen.de
      paths:
        - path: /
          pathType: Prefix
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
    acme.cert-manager.io/http01-edit-in-place: "true"
    kubernetes.io/ingress.class: nginx
    external-dns.alpha.kubernetes.io/hostname: login.klangregen.de
  tls:
    - hosts:
      - login.klangregen.de
      secretName: dex-cert
config:
  issuer: https://login.klangregen.de/dex/
  # The storage configuration determines where dex stores its state. Supported
  # options include SQL flavors and Kubernetes third party resources.
  #
  # See the documentation (https://dexidp.io/docs/storage/) for further information.
  storage:
    type: kubernetes
    config:
      inCluster: true

  # Configuration for the HTTP endpoints.
  web:
    http: 0.0.0.0:5556
  # Configuration for telemetry
  telemetry:
    http: 0.0.0.0:5558

  # Instead of reading from an external storage, use this list of clients.
  #
  # If this option isn't chosen clients may be added through the gRPC API.
  staticClients:
  - name: Grafana
    IDEnv: grafana.client-id
    secretEnv: grafana.client-secret
    redirectURIs:
    -  https://monitoring.klangregen.de/login/generic_oauth
  - name: Argocd
    IDEnv: client-id
    secretEnv: client-secret
    redirectURIs:
    -  https://argocd.klangregen.de/auth/callback
  connectors:
  - type: github
    # Required field for connector id.
    id: github
    # Required field for connector name.
    name: GitHub
    config:
      # Credentials can be string literals or pulled from the environment.
      clientID: $GITHUB_CLIENT_ID
      clientSecret: $GITHUB_CLIENT_SECRET
      redirectURI: https://login.klangregen.de/dex/callback
      orgs:
      - name: nce-acme
        # A white list of teams. Only include group claims for these teams.
        teams:
        - admin
        - zuschauer
      # Flag which indicates that all user groups and teams should be loaded.
      loadAllGroups: false

  # Let dex keep a list of passwords which can be used to login to dex.
  enablePasswordDB: false
YAML
  ]
}
