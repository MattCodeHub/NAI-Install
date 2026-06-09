#!/bin/bash
set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${GREEN}=================================================================\${NC}"
echo -e "${GREEN}   Phase 2: Download NAI Helm Charts & Container Images          \${NC}"
echo -e "${GREEN}=================================================================\${NC}"

read -r -p "Enter NAI Target Version [2.6.0]: " NAI_VERSION
NAI_VERSION=\${NAI_VERSION:-2.6.0}

STAGING_DIR="./nai-darksite-bundle"
mkdir -p "${STAGING_DIR}/charts" "${STAGING_DIR}/images"

echo -e "\${YELLOW}Fetching Helm Manifests...\${NC}"
helm repo add ntnx-charts https://nutanix.github.io/helm-releases > /dev/null 2>&1
helm repo update ntnx-charts > /dev/null 2>&1
helm pull ntnx-charts/nai-operators --version "\${NAI_VERSION}" --destination "\${STAGING_DIR}/charts"
helm pull ntnx-charts/nai-core --version "\${NAI_VERSION}" --destination "\${STAGING_DIR}/charts"

IMAGE_LIST=(
    "nutanix/nai-redis:v\${NAI_VERSION}"
    "nutanix/nai-jobs:v\${NAI_VERSION}"
    "nutanix/nai-clickhouse-operator:v\${NAI_VERSION}"
    "nutanix/nai-iep-operator:v\${NAI_VERSION}"
    "nutanix/nai-model-processor:v\${NAI_VERSION}"
    "nutanix/nai-inference-ui:v\${NAI_VERSION}"
)

render_progress() {
    local current=\$1
    local total=\$2
    local task=\$3
    local percent=\$(( current * 100 / total ))
    local completed=\$(( percent / 5 ))
    local remaining=\$(( 20 - completed ))
    local bar=""
    for ((i=0; i<completed; i++)); do bar="\${bar}█"; done
    for ((i=0; i<remaining; i++)); do bar="\${bar}░"; done
    echo -e "\r\${YELLOW}[\${bar}] \${percent}% | \${task}\${NC}\c"
}

total_images=\${#IMAGE_LIST[@]}
current_count=0

echo -e "\n\${YELLOW}Starting Container Asset Stream Integration...\${NC}"
for img in "\${IMAGE_LIST[@]}"; do
    FILE_NAME=\$(echo "\$img" | tr '/:' '_').tar
    
    render_progress "\$current_count" "\$total_images" "Pulling \$img"
    docker pull "docker.io/\$img" > /dev/null 2>&1
    
    render_progress "\$current_count" "\$total_images" "Saving \$img to disk"
    docker save "docker.io/\$img" -o "\${STAGING_DIR}/images/\${FILE_NAME}" > /dev/null 2>&1
    
    ((current_count++))
done

render_progress "\$total_images" "\$total_images" "All images localized successfully."
echo ""

echo -e "\${YELLOW}Compiling master tarball matrix...\${NC}"
tar -czf "nai-darksite-package-v\${NAI_VERSION}.tar.gz" -C "\${STAGING_DIR}" .

echo -e "\n\${GREEN}✔ Completed! Move 'nai-darksite-package-v\${NAI_VERSION}.tar.gz' to your darksite.\${NC}"
