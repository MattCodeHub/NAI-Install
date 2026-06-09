# Nutanix Enterprise AI (NAI) Deployment Toolkit for NKP

Welcome to the Nutanix Enterprise AI (NAI) Deployment Toolkit. This repository provides a structured, highly automated workflow for installing NAI into a Nutanix Kubernetes Platform (NKP) cluster. 

Whether your environment is fully connected to the internet or operating inside a highly secure, air-gapped (Dark Site) datacenter, this toolkit eliminates manual configuration errors by standardizing the certificate creation, asset preservation, and cluster instantiation processes.

---

## 🎯 What is Nutanix Enterprise AI (NAI)?

Nutanix Enterprise AI is an enterprise-grade AI inference platform designed to deploy, scale, and manage Large Language Models (LLMs) and foundational AI models on-premises with total data sovereignty. Built directly on top of the cloud-native infrastructure of **Nutanix Kubernetes Platform (NKP Pro/Ultimate)**, NAI provides:

* **Secure Inference Server APIs:** OpenAI-compatible API endpoints allowing developers to point existing applications straight to your private infrastructure.

* **Built-in LLM Management:** Seamless pulling, caching, and serving of open-source models (like Llama, Mistral, and Phi) from internal or secure external sources.

* **Advanced Observability:** Native integration with OpenTelemetry to track inference performance, token generation speed, and system latency.

* **Enterprise AI Labs:** Production-ready reference applications including turnkey chat interfaces and localized RAG (Retrieval-Augmented Generation) templates ("Talk To My Data").

---

## 🏗️ Architecture & Component Blueprint

When this toolkit executes, it deploys two foundational layers within the target `nai-system` namespace:

1.  **NAI Operators (`nai-operators`):** The orchestration brains of the platform. It installs custom resource controllers, an internal high-performance caching database (**Redis**), and a structured logging engine (**ClickHouse**).

2.  **NAI Core Services (`nai-core`):** The functional layer. This deploys the **NAI Intelligent Execution Engine (IEP)**, model processors, the OpenAI-compliant API router, and the web-based graphical user interfaces for your end users.

---

## 📋 Comprehensive Prerequisites Checklist

Before executing any script in this toolkit, ensure your infrastructure meets the following baseline architectural criteria.

### 1. Compute & Accelerators
* **NVIDIA GPUs:** Your NKP worker node pools must be equipped with enterprise-grade NVIDIA GPUs (e.g., H100, A100, L40S, A16, or L4).

* **NVIDIA GPU Operator:** Must be successfully deployed and validated via the NKP App Catalog. Run `kubectl get pods -n nvidia-gpu-operator` to ensure all GPU drivers and container runtimes are functional.

### 2. Enterprise Storage Foundations
NAI requires two distinct classes of high-performance storage mapped directly to your Nutanix cluster:

* **ReadWriteOnce (RWO):** Backed by **Nutanix Volumes** (typically named `nutanix-volume`). Used for isolated state storage, metrics tracking databases, and operational metadata.

* **ReadWriteMany (RWX):** Backed by **Nutanix Files** (e.g., `nai-nfs-storage`). **This is critical.** Large Language Models consist of massive multi-gigabyte shard files. This class allows multiple worker pods across different physical servers to read from the exact same cached model simultaneously.

### 3. Native Platform Dependencies
Ensure that the core NKP stack components are provisioned and active:
* **Envoy Gateway:** Utilized for high-throughput AI gateway routing and traffic shaping.
* **KServe & Knative:** Leveraged by NAI to orchestrate serverless, auto-scaling model inference frameworks.

---

## 🚀 Step-by-Step Implementation Guide

To accommodate strict enterprise security boundaries, this toolkit breaks the installation down into **four logical phases**. 

### 🔐 Phase 1: Certificate Management (`1-setup-certs.sh`)
* **Who runs this:** Security Administrators / Infrastructure Engineers.
* **Where to run it:** Inside the dark site, on the machine hosting your private container registry (or an administrative jumpbox).
* **What it does:** Generates a secure, cryptographically sound, Subject Alternative Name (SAN)-compliant Self-Signed Root Certificate Authority (CA) and server TLS certificate. Modern container engines (Docker/Podman/Containerd) will reject plain HTTP or non-SAN certificates. This script builds an immediate, trusted connection for your private image registry.

### 🌐 Phase 2: Asset Acquisition (`2-download-assets.sh`)
* **Who runs this:** DevOps / Platform Engineers.
* **Where to run it:** An **internet-connected** laptop, workstation, or staging jumpbox.
* **What it does:** Reaches out to the secure Nutanix Helm repositories and Docker Hub to fetch all essential software components. It automatically downloads the proper NAI Helm chart manifests and pulls the required container image assets, neatly bundling them into a single compressable distribution archive (`nai-darksite-package-vX.Y.Z.tar.gz`).
* *Note: For Connected-Site deployments, this staging step is skipped entirely.*

### 📦 Phase 3: Dark Site Registry Ingestion (`3-push-assets.sh`)
* **Who runs this:** Datacenter Operations / Registry Administrators.
* **Where to run it:** Inside the **air-gapped (Dark Site) datacenter**, on a jumpbox that has access to both your private container registry and your NKP cluster.
* **What it does:** Automatically unpacks the distribution bundle generated in Phase 2. It sequentially imports each container archive file, appends your corporate registry domain tags, authenticates to your internal image mirror, pushes the assets securely, and organizes the Helm manifests into a local charts cache directory.

### 🏁 Phase 4: Cluster Installation Execution (`4-install-nai.sh`)
* **Who runs this:** Kubernetes Platform Administrators.
* **Where to run it:** The primary administrative bastion host or machine where you run your active `kubectl` cluster commands.
* **What it does:** The final master deployment script. It cleanly prompts the operator to define their environmental variables (Connected vs. Air-Gapped, StorageClass names, Target version, and target workspace namespaces). It then builds the required Kubernetes primitives, injects image pull secrets, overrides registry pathways dynamically, and runs the sequential Helm tracking upgrades to stand up the live NAI platform.

---

## 🔍 Post-Deployment Verification

Once Phase 4 completes with a success message, you can monitor the deployment's stabilization by executing the following command:

```bash
kubectl get pods -n nai-system -w