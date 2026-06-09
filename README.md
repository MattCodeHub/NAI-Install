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
