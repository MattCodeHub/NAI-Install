
# Nutanix Enterprise AI (NAI) Deployment Toolkit for NKP

Welcome to the Nutanix Enterprise AI (NAI) Deployment Toolkit. This repository provides a structured, highly automated workflow for installing NAI into a Nutanix Kubernetes Platform (NKP) cluster. 

Whether your environment is fully connected to the internet or operating inside a highly secure, air-gapped (Dark Site) datacenter, this toolkit eliminates manual configuration errors by standardizing certificate creation, asset preservation, and cluster instantiation processes.

---

## 🎯 What is Nutanix Enterprise AI (NAI)?

Nutanix Enterprise AI is an enterprise-grade AI inference platform designed to deploy, scale, and manage Large Language Models (LLMs) and foundational AI models on-premises with total data sovereignty. Built directly on top of the cloud-native infrastructure of **Nutanix Kubernetes Platform (NKP Pro/Ultimate)**, NAI provides:

* **Secure Inference Server APIs:** OpenAI-compatible API endpoints allowing developers to point existing applications straight to your private infrastructure.
* **Built-in LLM Management:** Seamless pulling, caching, and serving of open-source models (like Llama, Mistral, and Phi) from internal or secure external sources.
* **Advanced Observability:** Native integration with OpenTelemetry to track inference performance, token generation speed, and system latency.
* **Enterprise AI Labs:** Production-ready reference applications including turnkey chat interfaces and localized RAG (Retrieval-Augmented Generation) templates ("Talk To My Data").

---

## 📂 Repository Folder Layout

Before executing any phase of the deployment, verify that your administrative staging root folder matches the structural framework below. 

```text
📁 nai-toolkit/               # The Primary Installation Toolkit Directory
├── 📁 .github/
│   └── 📁 workflows/
│       └── 📄 validate.yaml  # Automated shell validation configuration
├── 📄 .gitignore             # File exclusion rules
├── 📄 README.md              # Global administrative manual (This file)
├── 📜 1-setup-certs.sh       # Dark Site Phase 1: TLS Certificate Automation
├── 📜 2-download-assets.sh   # Dark Site Phase 2: Staging Mirror Downloader
├── 📜 3-push-assets.sh       # Dark Site Phase 3: Local Mirror Registry Sync
└── 📜 4-install-nai.sh       # Dark Site/Connected Phase 4: Active Installer

⚠️ CRITICAL REQUIREMENT: Bastion Host & Kubectl Availability
IMPORTANT: To execute the final cluster installation script (4-install-nai.sh), you must have access to an administrative Bastion Host, Jumpbox, or Management Workstation that has active kubectl and helm utilities installed.

While a formal, dedicated "Bastion" server is not strictly required, the machine running the installation MUST have direct network line-of-sight to the Kubernetes API Server of your NKP cluster and be authenticated with a valid cluster context (kubeconfig).

Tooling Breakdown by Machine Type
💻 Machine 1: The Internet Staging Machine (Runs Script #2)
Used in Dark Site workflows to pull public assets down from the internet.

Required Tools: docker or podman (To pull and package multi-gigabyte container image layers), helm (To pull chart packages).

Kubectl Required? No.

Network Scope: Public Internet Access.

🔒 Machine 2: The Secure Dark Site Registry Host / Jumpbox (Runs Scripts #1 & #3)
The on-premises environment hosting your private container registry mirror (e.g., Harbor).

Required Tools: docker or podman (To unpack and push image layers into the local mirror), openssl (To generate local TLS registry certificates).

Kubectl Required? No.

Network Scope: Local network access to the private registry web engine.

⚙️ Machine 3: The Cluster Deployment Machine / Bastion (Runs Script #4)
The workstation interacting directly with the active Kubernetes infrastructure.

Required Tools: kubectl (Must be configured with a working kubeconfig context tracking the cluster), helm (To apply direct system upgrades to the cluster).

Docker/Podman Required? No.

Network Scope: Mandatory network line-of-sight to the Kubernetes API Server of the NKP cluster.

📋 Infrastructure & Storage Prerequisites Checklist
Before executing any cluster installation commands, verify that your backend Nutanix infrastructure meets the following baseline architectural criteria:

1. Compute & Accelerators
NVIDIA GPUs: Your NKP worker node pools must be equipped with enterprise-grade NVIDIA GPUs (e.g., H100, A100, L40S, A16, or L4).

NVIDIA GPU Operator: Must be successfully deployed and validated via the NKP App Catalog. Run kubectl get pods -n nvidia-gpu-operator to ensure all GPU drivers and container runtimes are functional.

2. Enterprise Storage Foundations
NAI requires two distinct classes of high-performance storage mapped directly to your Nutanix cluster:

ReadWriteOnce (RWO): Backed by Nutanix Volumes (typically named nutanix-volume). Used for isolated state storage, metrics tracking databases, and operational metadata.

ReadWriteMany (RWX): Backed by Nutanix Files (e.g., nai-nfs-storage). This is critical. Large Language Models consist of massive multi-gigabyte shard files. This class allows multiple worker pools across different physical servers to read from the exact same cached model simultaneously.

3. Native Platform Dependencies
Ensure that the core NKP stack components are provisioned and active:

Envoy Gateway: Utilized for high-throughput AI gateway routing and traffic shaping.

KServe & Knative: Leveraged by NAI to orchestrate serverless, auto-scaling model inference frameworks.

🚀 Step-by-Step "How-To" Implementation Guide
Option A: Internet-Connected Site Workflow (Fast Track)
If your deployment machine has direct access to both the internet and the NKP cluster, skip the staging steps and execute the installation immediately from your kubectl-enabled workstation:

Bash
# 1. Enter the toolkit directory
cd nai-toolkit

# 2. Make the install script executable
chmod +x 4-install-nai.sh

# 3. Run the installer and select Option 1 when prompted
./4-install-nai.sh
Option B: Air-Gapped / Dark Site Workflow (Detailed Manual)
Follow these four sequential phases to safely bridge assets across your air-gapped network boundary and run the dark-site installation playbook.

Phase 1: Generate Private Registry Certificates
Execute this phase on your secure dark-site registry jumpbox to create trusted local TLS credentials.

Navigate into the toolkit directory:

Bash
cd nai-toolkit
Unshackle permissions and execute the cert generator:

Bash
chmod +x 1-setup-certs.sh
./1-setup-certs.sh
When prompted, enter your local target registry domain (e.g., registry.local or harbor.ntnx.internal).

Distribute Trust (Crucial Step): Move the newly created ./nai-certs/rootCA.crt to your dark-site jumpbox system trust store so your container engine accepts connections without throwing security errors:

For RHEL / Rocky Linux:

Bash
sudo cp ./nai-certs/rootCA.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
For Ubuntu / Debian:

Bash
sudo cp ./nai-certs/rootCA.crt /usr/local/share/ca-certificates/nai-rootCA.crt
sudo update-ca-certificates
Phase 2: Staging Asset Acquisition (Internet-Side VM)
Execute this phase on an internet-enabled staging machine to compile the system package.

Ensure docker (or podman) and helm are fully active on the host machine.

Run the acquisition script:

Bash
chmod +x 2-download-assets.sh
./2-download-assets.sh
Enter your desired NAI version (Defaults to 2.6.0).

Export Artifact: The script will pull down public Helm chart definitions and dump compressed .tar images into a single deployable master package named nai-darksite-package-v2.6.0.tar.gz. Transfer this file via your company's secure hardware data-bridge into the dark site.

Phase 3: Ingest Assets to the Local Registry (Dark-Site Jumpbox)
Execute this phase inside the secure datacenter to extract and register software footprints into your local container mirror.

Place the nai-darksite-package-v2.6.0.tar.gz directly into your dark-site nai-toolkit/ directory.

Authenticate your local container daemon to your private target registry mirror:

Bash
docker login <your-private-registry-url>
Execute the payload upload engine:

Bash
chmod +x 3-push-assets.sh
./3-push-assets.sh
Provide the path to the package and your private registry FQDN. The utility will automatically run docker load, alter target namespace tracking metadata labels via docker tag, and force sync the container layers up to your on-premises hub. It also unpacks the offline Helm manifests safely into the local ./charts/ path.

Phase 4: Execute Cluster Installation (Requires Bastion / Kubectl)
Execute this phase on your active cluster administrative deployment node to spin up the running infrastructure instances.

Verify that your current kubectl context is targeting the proper production cluster:

Bash
kubectl config current-context
Fire off the master configuration installation engine:

Bash
chmod +x 4-install-nai.sh
./4-install-nai.sh
Select Option 2 (Air-Gapped / Dark Site) when challenged by the console interactive interface.

Provide the local parameters matching your active environment:

Private Registry URL: (e.g., registry.local)

Path to Root CA: (Defaults to ./nai-certs/rootCA.crt)

RWX StorageClass Name: Enter your Nutanix Files target definition layout.

RWO StorageClass Name: Enter your Nutanix Volumes target definition layout.

The script will intercept standard helm remote operations, read configuration maps directly from your offline ./charts/ bundles, bypass open-internet verification checkpoints by reading your specified local --ca-file, and apply changes to your cluster nodes.

🔍 Post-Deployment Verification
Once Phase 4 completes with a success message, monitor the stabilization of your AI workspace by executing:

Bash
kubectl get pods -n nai-system -w
Successful Deployment Milestones:
iam-database-bootstrap-... will transition through initialization states and reach a Completed status.

chi-nai-clickhouse-server-... and nai-redis-... stateful pods will display a healthy Running status with all ready containers active.

The nai-inference-ui and API pods will initialize, signaling that the graphical deployment dashboard and OpenAI endpoints are active and waiting to serve your users.

💡 Pro-Tip: To locate your public web access portal link, inspect the HTTP/HTTPS routing configurations generated inside your Envoy Gateway configuration space:

Bash
kubectl get gateway -n nai-system
