#!/bin/bash
#
# Install:
#   Linkerd
#   ArgoCD
#   Add more...

# TODO:
#   Add getopts
#   Make sure required tools are installed
#   correct az sub, az aks creds to temp kube config file
#   More...

# PREREQS:
#   Add secret "esi-grafana-env-vars" to kv-<aks cluster name> with the following contents:
#   {"GF_SERVER_ROOT_URL":"https://<aks cluster name>-grafana.cbreesi.com","GF_SMTP_ENABLED":"true","GF_SMTP_HOST":"smtp.mailgun.org:587","GF_SMTP_USER":"REDACTED@mg.thinkesi.com","GF_SMTP_PASSWORD":"REDACTED","GF_SMTP_FROM_ADDRESS":"grafana@mg.thinkesi.com","GF_SMTP_FROM_NAME":"Grafana-Alerts","GF_AUTH_OKTA_ENABLED":"true","GF_AUTH_OKTA_CLIENT_ID":"REDACTED","GF_AUTH_OKTA_CLIENT_SECRET":"REDACTED","GF_AUTH_OKTA_AUTH_URL":"https://esi.okta.com/oauth2/v1/authorize","GF_AUTH_OKTA_TOKEN_URL":"https://esi.okta.com/oauth2/v1/token","GF_AUTH_OKTA_API_URL":"https://esi.okta.com/oauth2/v1/userinfo","GF_USERS_AUTO_ASSIGN_ORG_ROLE":"Editor"}
#
#   Okta app for grafana
#   Okta app for ArgoCD?


#-----------------------------------------------------------------------------------------
# deploy aks cluster with terraform
# deploy key vaults:
#   kv-esi-common (will contain wildcard tls certs and possibly other things)
#   kv-<aks cluster name> (will contain cluster level secrets for things like kps)

# bootstrap-aks-cluster.sh
#   - install linkerd
#   - install argocd
#   - argocd: create project named aks-infrastructure
#   - argocd: create repo(s)
#   - install helm charts (via argocd Application resources):
#       cnpg operator
#       external-secrets
#       kube-prometheus-stack
#       loki
#       ingress-nginx
#       ?
#   - external-secrets: create a k8s secret named kv-esi-common-creds that will be used by the common css
#   - external-secrets: css that maps to kv-esi-common (this is an existing key vault that contains tls certs and possibly other things)
#   - external-secrets: css that maps to kv-<aks cluster name>

# Customer Prism git repo	
#   - manifests/external-secrets:
#      css that maps to kv-prism-<customer name>
#      secrets that should be synced from the customer's key vault
#   - manifests/postgres: databases (iot, mqttauth)
#   - manifests/?

# argocd-bootstrap-customer.sh
#   - deploy kv-prism-<customer name> key vault
#   - create secrets in the key vault
#   - external-secrets: create a k8s secret named kv-prism-<customer name>-creds that will be used by the css
#   - argocd: create project named prism-<customer name>
#   - argocd: create repo resource pointing to customer's git repo
#   - install helm charts (via argocd Application resources):
#       redis
#       kafka
#   - argocd: create argocd Application resources  
#-----------------------------------------------------------------------------------------

temp_kube_config_file=/tmp/bootstrap_aks_kube_config
argocd_helm_values_file=/tmp/argocd-helm-values.yaml
namespace=argocd
grafana_config_secret_name="esi-grafana-env-vars"
common_key_vault_name=kv-esi-common
common_key_vault_sp_creds_secret=kv-esi-common-creds


# REMOVE FOLLOWING LINES AND USE PARAMETERS AND EXTERNAL SECRETS INSTEAD !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ingress_nginx_lb_ip="10.0.1.10"
azure_sub=CBREESI
aks_cluster_resource_group=adam-cnpg-poc-rg
aks_cluster=aks-adam-cnpg-poc
grafana_pvc_size="50Gi"
grafana_admin_password="adamwashere"
grafana_server_fqdn="${aks_cluster}-grafana.cbreesi.com"
prometheus_pvc_size="50Gi"
mailgun_smtp_server="smtp.mailgun.org:587"
prometheus_alerts_smtp_username="prometheus@mg.thinkesi.com"
prometheus_alerts_smtp_password="not-correct-password"
prometheus_alerts_smtp_to="esicloudteam@mg.thinkesi.com"
loki_pvc_size="100Gi"
common_key_vault_sp_client_id='d3f22df0-da0d-4754-9f59-3981a798422a'
common_key_vault_sp_client_secret='WR08Q~-O5uib05VI1v-HJfgsInQZuhE.WWGNGc5E'
aks_key_vault_name="kv-${aks_cluster}"
argocd_fqdn="${aks_cluster}-argocd.cbreesi.com"


# Source in functions
. ./_functions_bootstrap-aks-cluster

# # THE FOLLOWING COMMAND IS TEMPORARY. FIND ANOTHER WAY...
# kubectl -n monitoring create secret generic esi-grafana-env-vars \
#   --from-literal=GF_SERVER_ROOT_URL="https://${grafana_server_fqdn}" \
#   --from-literal=GF_SMTP_ENABLED='true' \
#   --from-literal=GF_SMTP_HOST="$mailgun_smtp_server" \
#   --from-literal=GF_SMTP_USER="$grafana_smtp_username" \
#   --from-literal=GF_SMTP_PASSWORD="$grafana_smtp_password" \
#   --from-literal=GF_SMTP_FROM_ADDRESS="$grafana_smtp_username" \
#   --from-literal=GF_SMTP_FROM_NAME="$grafana_smtp_from_display_name" \
#   --from-literal=GF_AUTH_OKTA_ENABLED='true' \
#   --from-literal=GF_AUTH_OKTA_CLIENT_ID="$grafana_okta_client_id" \                                                                                              
#   --from-literal=GF_AUTH_OKTA_CLIENT_SECRET="$grafana_okta_client_secret" \                                                                                    
#   --from-literal=GF_AUTH_OKTA_AUTH_URL="$okta_auth_url" \
#   --from-literal=GF_AUTH_OKTA_TOKEN_URL="$okta_token_url" \                                                                               
#   --from-literal=GF_AUTH_OKTA_API_URL="$okta_api_url" \
#   --from-literal=GF_USERS_AUTO_ASSIGN_ORG_ROLE="$grafana_okta_users_auto_assign_org_role"


#--------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------
set-environment

install-argocd      # THIS FUNCTION HAS A LINE THAT WILL NEED TO BE CHANGED

change-argocd-admin-password

connect-bootstrap-git-repo

create-argocd-aks-infrastructure-project

create-infrastructure-root-app

# add-third-party-helm-repos

# install-third-party-helm-charts

# sync-external-secrets-chart

# create-external-secrets-css

# create-external-secrets-common

# create-external-secrets-aks-infrastructure

# sync-charts

# create-ingress-resources

output

cleanup
