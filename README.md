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

## ⚠️ CRITICAL REQUIREMENT: Bastion Host & Kubectl Availability

> **IMPORTANT:** To execute the final cluster installation script (`4-install-nai.sh`), you must have access to an administrative **Bastion Host, Jumpbox, or Management Workstation** that has active `kubectl` and `helm` utilities installed. 
>
> While a formal, dedicated "Bastion" server is not strictly required, the machine running the installation **MUST** have direct network line-of-sight to the Kubernetes API Server of your NKP cluster and be authenticated with a valid cluster context (`kubeconfig`).

### Tooling Breakdown by Machine Type

#### Machine 1: The Internet Staging Machine (Runs Script #2)
*Used in Dark Site workflows to pull public assets down from the internet.*
* **Required Tools:** `docker` or `podman` (To pull and package multi-gigabyte container image layers), `helm` (To pull chart packages).
* **Kubectl Required?** No. 
* **Network Scope:** Public Internet Access.

#### Machine 2: The Secure Dark Site Registry Host / Jumpbox (Runs Scripts #1 & #3)
*The on-premises environment hosting your private container registry mirror (e.g., Harbor).*
* **Required Tools:** `docker` or `podman` (To unpack and push image layers into the local mirror), `openssl` (To generate local TLS registry certificates).
* **Kubectl Required?** No.
* **Network Scope:** Local network access to the private registry web engine.

#### Machine 3: The Cluster Deployment Machine / Bastion (Runs Script #4)
*The workstation interacting directly with the active Kubernetes infrastructure.*
* **Required Tools:** `kubectl` (Must be configured with a working `kubeconfig` context targeting the cluster), `helm` (To apply direct system upgrades to the cluster).
* **Docker/Podman Required?** No.
* **Network Scope:** **Mandatory network line-of-sight to the Kubernetes API Server of the NKP cluster.**

---

## 📋 Infrastructure & Storage Prerequisites Checklist

Before executing any cluster installation commands, verify that your backend Nutanix infrastructure meets the following baseline architectural criteria:

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

## 🚀 Step-by-Step "How-To" Implementation Guide

### Option A: Internet-Connected Site Workflow (Fast Track)
If your deployment machine has direct access to both the internet and the NKP cluster, skip the staging steps and execute the installation immediately from your `kubectl`-enabled workstation:

```bash
# 1. Enter the toolkit directory
cd nai-toolkit

# 2. Make the install script executable
chmod +x 4-install-nai.sh

# 3. Run the installer and select Option 1 when prompted
./4-install-nai.sh
