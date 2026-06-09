# Nutanix Enterprise AI (NAI) Deployment Guide

This repository contains the toolkit to deploy NAI into an internet-connected or air-gapped (Dark Site) NKP cluster.

## Deployment Steps
1. **Connected Site:** Run `4-install-nai.sh` and select option 1.
2. **Dark Site Workflow:**
   - Run `1-setup-certs.sh` to generate local registry certificates.
   - Run `2-download-assets.sh` on an internet-connected machine to archive images/charts.
   - Run `3-push-assets.sh` on the dark site jumpbox to unpack and push images to your registry.
   - Run `4-install-nai.sh` on your cluster bastion to complete the installation.
