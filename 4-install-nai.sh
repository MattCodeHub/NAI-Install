#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}=================================================================\${NC}"
echo -e "${GREEN}   Phase 4: Execute Nutanix Enterprise AI (NAI) Installation     \${NC}"
echo -e "${GREEN}=================================================================\${NC}"

CURRENT_CONTEXT=\$(kubectl config current-context 2>/dev/null)
if [ -z "$CURRENT_CONTEXT" ]; then echo -e "${RED}Error: No active Kubernetes context.\${NC}"; exit 1; fi
echo -e "${YELLOW}Target Cluster:\${NC} \${CURRENT_CONTEXT}"

echo -e "\nSelect Installation Type:"
echo "1) Internet-Connected Site"
echo "2) Air-Gapped / Dark Site"
read -r -p "Selection (1 or 2): " DEPLOY_CHOICE

read -r -p "Enter NAI Target Version [2.6.0]: " NAI_VERSION
NAI_VERSION=\${NAI_VERSION:-2.6.0}
read -r -p "RWX StorageClass (Nutanix Files) [nai-nfs-storage]: " RWX_SC
RWX_SC=\${RWX_SC:-nai-nfs-storage}
read -r -p "RWO StorageClass (Nutanix Volumes) [nutanix-volume]: " RWO_SC
RWO_SC=\${RWO_SC:-nutanix-volume}
read -r -p "NKP Workspace Namespace [kommander-default-workspace]: " NKP_NS
NKP_NS=\${NKP_NS:-kommander-default-workspace}

kubectl create namespace nai-system --dry-run=client -o yaml | kubectl apply -f -

if [ "$DEPLOY_CHOICE" == "2" ]; then
    read -r -p "Enter Internal Private Registry URL (e.g., registry.local): " REGISTRY_URL
    read -r -p "Path to Custom Root CA Certificate [./nai-certs/rootCA.crt]: " CA_PATH
    CA_PATH=\${CA_PATH:-./nai-certs/rootCA.crt}
    
    HELM_OPTS="--ca-file=\${CA_PATH}"
    CHART_OPTS_OPTS="./charts/nai-operators-\${NAI_VERSION}.tgz"
    CHART_CORE_OPTS="./charts/nai-core-\${NAI_VERSION}.tgz"
    
    cat <<EOF > values-operators.yaml
imagePullSecret: { credentials: { registry: \${REGISTRY_URL} } }
naiRedis: { naiRedisImage: { name: \${REGISTRY_URL}/nutanix/nai-redis } }
naiJobs: { naiJobsImage: { image: \${REGISTRY_URL}/nutanix/nai-jobs } }
nai-clickhouse-operator: { operator: { image: { registry: \${REGISTRY_URL}/nutanix } } }
EOF

    cat <<EOF > values-core.yaml
imagePullSecret: { credentials: { registry: \${REGISTRY_URL} } }
global:
  nkpWorkspaceNamespace: \${NKP_NS}
  storage: { rwxClassName: \${RWX_SC}, rwoClassName: \${RWO_SC} }
naiApi: { storageClassName: \${RWX_SC} }
naiIepOperator:
  iepOperatorImage: { image: \${REGISTRY_URL}/nutanix/nai-iep-operator }
  modelProcessorImage: { image: \${REGISTRY_URL}/nutanix/nai-model-processor}
naiInferenceUi: { naiUiImage: { image: \${REGISTRY_URL}/nutanix/nai-inference-ui } }
EOF
else
    read -r -p "Enter Docker Hub / Nutanix Registry Username: " DOCKER_USER
    read -r -p "Enter Registry Token/Password: " -s DOCKER_PASS
    echo ""
    
    helm repo add ntnx-charts https://nutanix.github.io/helm-releases
    helm repo update ntnx-charts
    
    kubectl create secret docker-registry registry-image-pull-secret \
      --docker-server=docker.io --docker-username="$DOCKER_USER" --docker-password="$DOCKER_PASS" \
      -n nai-system --dry-run=client -o yaml | kubectl apply -f -
      
    CHART_OPTS_OPTS="ntnx-charts/nai-operators --version \${NAI_VERSION}"
    CHART_CORE_OPTS="ntnx-charts/nai-core --version \${NAI_VERSION}"
    HELM_OPTS=""
    
    cat <<EOF > values-operators.yaml
imagePullSecret: { credentials: { username: "${DOCKER_USER}", password: "${DOCKER_PASS}" } }
global: { imagePullSecrets: [ { name: registry-image-pull-secret } ] }
EOF

    cat <<EOF > values-core.yaml
imagePullSecret: { credentials: { username: "${DOCKER_USER}", password: "${DOCKER_PASS}" } }
global:
  nkpWorkspaceNamespace: \${NKP_NS}
  storage: { rwxClassName: \${RWX_SC}, rwoClassName: \${RWO_SC} }
naiApi: { storageClassName: \${RWX_SC} }
EOF
fi

helm upgrade --install nai-operators \${CHART_OPTS_OPTS} -n nai-system --wait -f values-operators.yaml \${HELM_OPTS} --insecure-skip-tls-verify
helm upgrade --install nai-core \${CHART_CORE_OPTS} -n nai-system --wait -f values-core.yaml \${HELM_OPTS} --insecure-skip-tls-verify

rm -f values-operators.yaml values-core.yaml
echo -e "\n\${GREEN}✔ NAI Platform Up and Initialized on NKP!\${NC}"
