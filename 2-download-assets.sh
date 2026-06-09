#!/bin/bash
set -e
GREEN='\033[0;32m'
NC='\033[0m'

clear
echo -e "${GREEN}=================================================================\${NC}"
echo -e "${GREEN}   Phase 2: Download NAI Helm Charts & Container Images          \${NC}"
echo -e "${GREEN}=================================================================\${NC}"

read -r -p "Enter NAI Target Version [2.6.0]: " NAI_VERSION
NAI_VERSION=\${NAI_VERSION:-2.6.0}

STAGING_DIR="./nai-darksite-bundle"
mkdir -p "${STAGING_DIR}/charts" "${STAGING_DIR}/images"

helm repo add ntnx-charts https://nutanix.github.io/helm-releases
helm repo update ntnx-charts
helm pull ntnx-charts/nai-operators --version "${NAI_VERSION}" --destination "${STAGING_DIR}/charts"
helm pull ntnx-charts/nai-core --version "${NAI_VERSION}" --destination "${STAGING_DIR}/charts"

IMAGE_LIST=(
    "nutanix/nai-redis:v\${NAI_VERSION}"
    "nutanix/nai-jobs:v\${NAI_VERSION}"
    "nutanix/nai-clickhouse-operator:v\${NAI_VERSION}"
    "nutanix/nai-iep-operator:v\${NAI_VERSION}"
    "nutanix/nai-model-processor:v\${NAI_VERSION}"
    "nutanix/nai-inference-ui:v\${NAI_VERSION}"
)

for img in "${IMAGE_LIST[@]}"; do
    FILE_NAME=\$(echo "$img" | tr '/:' '_').tar
    docker pull "docker.io/$img"
    docker save "docker.io/$img" -o "${STAGING_DIR}/images/\${FILE_NAME}"
done

tar -czf "nai-darksite-package-v\${NAI_VERSION}.tar.gz" -C "$STAGING_DIR" .
echo -e "\n\${GREEN}✔ Completed! Move 'nai-darksite-package-v\${NAI_VERSION}.tar.gz' to your darksite.\${NC}"
