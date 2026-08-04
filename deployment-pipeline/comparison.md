# KijaniKiosk Deployment Approaches: Blue/Green vs Containerized

## Overview

This document compares two deployment approaches implemented for the KijaniKiosk payments service: the blue/green deployment on virtual machines and the containerized deployment on Kubernetes. The comparison is based on actual measurements from our production pipeline.

## Comparison Table

| Concern | Blue/Green on VMs | Containerized on Kubernetes |
|---------|-------------------|----------------------------|
| **Deployment mechanism** | Systemd services on two separate VMs. Nginx routes traffic between them. Traffic is switched by updating the nginx configuration and reloading it. | Kubernetes deployments with rolling updates. Traffic is routed through a Service that handles load balancing between Pods. The rollout is managed by the Kubernetes controller. |
| **Rollback mechanism** | A bash script switches the nginx proxy back to the previous environment. The post-deploy monitor detects failures and triggers the rollback script automatically. | Rolling back is a simple command: `kubectl rollout undo`. Kubernetes reverts to the previous revision instantly. The cluster also handles Pod failures automatically. |
| **Failure recovery** | The monitor polls the health endpoint every 5 seconds. After 2 consecutive failures, it triggers a rollback. Recovery time is under 90 seconds. | Kubernetes uses liveness and readiness probes. If a Pod fails, it is restarted automatically. If the deployment fails, the previous revision is restored. Self-healing time is measured in seconds. |
| **Scaling** | Scaling requires provisioning new VMs and configuring them. This is a manual process that takes minutes. | Scaling is a single command: `kubectl scale deployment kk-payments --replicas=5`. The cluster handles everything automatically. |

## Measured Numbers

**Self-healing time (containerized):** When a Pod was deleted, a new Pod reached the Running state in approximately 45 seconds. This was measured during the self-healing test on the production cluster.

**Image size reduction:** The container image was reduced from a baseline of 186MB to 45.6MB using multi-stage builds and Alpine Linux. This represents a 75% reduction in image size.

## What the Container Approach Does Not Yet Solve

The containerized deployment does not yet solve configuration management. The application still requires environment variables and configuration files. In the blue/green deployment, these were stored on the VM. In the container approach, we need a solution for managing configuration across environments.

The next project will introduce ConfigMaps and Secrets to address this gap. This will allow us to manage configuration declaratively and securely across all environments.

Additionally, the container approach does not yet include a comprehensive monitoring stack. While Kubernetes provides basic health checks, we need to add Prometheus and Grafana for full observability.

The blue/green deployment already has these components integrated. The container approach will catch up in the next phase of the project.
