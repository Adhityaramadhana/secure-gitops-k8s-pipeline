# Portfolio — Secure GitOps K8s Pipeline Demo

**Repository:** https://github.com/Adhityaramadhana/secure-gitops-k8s-pipeline

## Overview
A Kubernetes-focused DevOps demo that shows a full CI pipeline with quality gates, security checks, policy-as-code validation, and a real deployment to a local Kubernetes cluster (Kind) using Helm, followed by automated smoke tests.

## What I implemented
- FastAPI service with health/version endpoints
- Quality gates:
  - `ruff` lint
  - `mypy` type checking
  - `pytest` unit tests
- Containerization:
  - Docker build in CI
  - Security hardening: non-root runtime with numeric UID (`runAsUser: 1000`)
- Security scanning:
  - Trivy scan with SARIF upload to GitHub Security
- Kubernetes delivery checks:
  - Helm template rendering
  - `kubeconform` manifest validation
  - `conftest` (OPA/Rego) policy checks
- Deployment simulation:
  - Create Kind cluster in CI
  - Load Docker image into Kind
  - Deploy via Helm
  - Rollout verification + smoke tests (`/health`, `/version`)

## Root cause & fix (real issue encountered)
During rollout, the deployment was stuck due to `CreateContainerConfigError`:
- Root cause: `runAsNonRoot: true` could not be verified with a non-numeric user (`appuser`)
- Fix: set `runAsUser: 1000` so Kubernetes can verify the container runs as non-root

## How to verify (locally)
```bash
# Clone the repository
git clone https://github.com/Adhityaramadhana/secure-gitops-k8s-pipeline.git
cd secure-gitops-k8s-pipeline

# Set up Python environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt -r requirements-dev.txt

# Run quality checks
PYTHONPATH=. pytest -q
ruff check .
mypy .

# Run the application locally
uvicorn app.main:app --reload
# Visit http://localhost:8000/health and http://localhost:8000/version

# Build and test with Docker + Kind
docker build -t local/secure-gitops-k8s-pipeline:ci .
kind create cluster --name demo
kind load docker-image local/secure-gitops-k8s-pipeline:ci --name demo

# Deploy with Helm
helm upgrade --install demo chart/secure-gitops-k8s-pipeline \
  --set image.repository=local/secure-gitops-k8s-pipeline \
  --set image.tag=ci

# Verify deployment
kubectl rollout status deployment/demo --timeout=180s
kubectl get pods
kubectl port-forward svc/demo 8000:8000

# Cleanup
kind delete cluster --name demo
```

## CI/CD Pipeline Stages
1. **Code Quality** - Linting, type checking, unit tests
2. **Build** - Docker image creation
3. **Security** - Trivy vulnerability scanning with SARIF upload
4. **Validation** - Kubeconform schema validation
5. **Policy** - Conftest/OPA policy enforcement
6. **Deploy** - Helm deployment to Kind cluster
7. **Verify** - Rollout status check and smoke tests

## Technologies Used
- **Language:** Python 3.12, FastAPI
- **Testing:** pytest, mypy, ruff
- **Container:** Docker
- **Orchestration:** Kubernetes, Helm
- **CI/CD:** GitHub Actions
- **Security:** Trivy, OPA/Conftest
- **Tools:** Kind, kubeconform

## Key Learnings
- Implemented security best practices (non-root containers, security context)
- Debugged Kubernetes deployment issues using pod events and logs
- Applied policy-as-code validation with OPA/Rego
- Created end-to-end CI pipeline with deployment verification
- Handled security context configuration for Kubernetes compliance

## Screenshots
See `.github/workflows/ci.yml` for complete pipeline configuration and workflow run results in the Actions tab of the repository.
