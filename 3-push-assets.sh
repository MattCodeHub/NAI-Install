#!/bin/bash
set -e
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}=================================================================\${NC}"
echo -e "${GREEN}   Phase 3: Push NAI Assets to Internal Private Registry         \${NC}"
echo -e "${GREEN}=================================================================\${NC}"

read -r -p "Enter Target Tarball Package Path [./nai-darksite-package-v2.6.0.tar.gz]: " BUNDLE_PATH
BUNDLE_PATH=\${BUNDLE_PATH:-./nai-darksite-package-v2.6.0.tar.gz}

if [ ! -f "$BUNDLE_PATH" ]; then echo -e "${RED}Error: Tarball not found.\${NC}"; exit 1; fi

read -r -p "Enter Internal Private Registry URL (e.g., registry.local): " REGISTRY_URL
if [ -z "$REGISTRY_URL" ]; then echo -e "${RED}Error: Registry URL required.\${NC}"; exit 1; fi

EXTRACT_DIR="./unpacked-nai"
mkdir -p "$EXTRACT_DIR"
tar -xzf "$BUNDLE_PATH" -C "$EXTRACT_DIR"

for tar_file in "${EXTRACT_DIR}/images"/*.tar; do
    LOAD_OUTPUT=\$(docker load -i "$tar_file")
    ORIG_TAG=\$(echo "$LOAD_OUTPUT" | awk '/Loaded image/ {print \$3}')
    CLEAN_TAG=\$(echo "$ORIG_TAG" | sed 's|^docker.io/||')
    NEW_TAG="\${REGISTRY_URL}/\${CLEAN_TAG}"
    
    docker tag "$ORIG_TAG" "$NEW_TAG"
    docker push "$NEW_TAG"
done

mkdir -p ./charts
cp "${EXTRACT_DIR}/charts"/* ./charts/
echo -e "\n\${GREEN}✔ Sync complete! Helm charts staged in ./charts/\${NC}"
