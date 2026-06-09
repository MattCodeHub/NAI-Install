#!/bin/bash
set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}=================================================================\${NC}"
echo -e "${GREEN}   Phase 3: Push NAI Assets to Internal Private Registry         \${NC}"
echo -e "${GREEN}=================================================================\${NC}"

read -r -p "Enter Target Tarball Package Path [./nai-darksite-package-v2.6.0.tar.gz]: " BUNDLE_PATH
BUNDLE_PATH=\${BUNDLE_PATH:-./nai-darksite-package-v2.6.0.tar.gz}

if [ ! -f "\$BUNDLE_PATH" ]; then echo -e "\${RED}Error: Tarball not found.\${NC}"; exit 1; fi

read -r -p "Enter Internal Private Registry URL (e.g., registry.local): " REGISTRY_URL
if [ -z "\$REGISTRY_URL" ]; then echo -e "\${RED}Error: Registry URL required.\${NC}"; exit 1; fi

EXTRACT_DIR="./unpacked-nai"
mkdir -p "\$EXTRACT_DIR"

echo -e "\${YELLOW}Unpacking software archive matrix...\${NC}"
tar -xzf "\$BUNDLE_PATH" -C "\$EXTRACT_DIR"

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
    echo -e "\r\${YELLOW}[${bar}] \${percent}% | \${task}\${NC}\c"
}

image_files=("\${EXTRACT_DIR}"/images/*.tar)
total_images=\${#image_files[@]}
current_count=0

echo -e "\n\${YELLOW}Hydrating Local Registry Mirror Engine...\${NC}"
for tar_file in "\${image_files[@]}"; do
    if [ -e "\$tar_file" ]; then
        base_name=\$(basename "\$tar_file")
        
        render_progress "\$current_count" "\$total_images" "Loading Layer: \$base_name"
        LOAD_OUTPUT=\$(docker load -i "\$tar_file" 2>/dev/null)
        
        ORIG_TAG=\$(echo "$LOAD_OUTPUT" | awk '/Loaded image/ {print \$3}')
        CLEAN_TAG=\$(echo "\$ORIG_TAG" | sed 's|^docker.io/||')
        NEW_TAG="\${REGISTRY_URL}/\${CLEAN_TAG}"
        
        render_progress "\$current_count" "\$total_images" "Pushing Registry Layer: \$CLEAN_TAG"
        docker tag "\$ORIG_TAG" "\$NEW_TAG" > /dev/null 2>&1
        docker push "\$NEW_TAG" > /dev/null 2>&1
        
        ((current_count++))
    fi
done

render_progress "\$total_images" "\$total_images" "Registry mirror synchronization successful."
echo ""

mkdir -p ./charts
cp "\${EXTRACT_DIR}/charts"/* ./charts/
echo -e "\n\${GREEN}✔ Sync complete! Helm charts staged in ./charts/\${NC}"
