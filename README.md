# Secure GitOps K8s Pipeline Demo

[![CI](https://github.com/Adhityaramadhana/secure-gitops-k8s-pipeline/actions/workflows/ci.yml/badge.svg)](https://github.com/Adhityaramadhana/secure-gitops-k8s-pipeline/actions/workflows/ci.yml)

A production-grade CI/CD pipeline demo showcasing security-first Kubernetes deployment with quality gates, policy-as-code validation, and automated testing.

## Features

- **Quality Gates:** Linting (ruff), type checking (mypy), unit tests (pytest)
- **Security Scanning:** Trivy vulnerability scanning with SARIF upload to GitHub Security
- **Policy-as-Code:** OPA/Conftest validation for Kubernetes manifests
- **Kubernetes Validation:** Schema validation with kubeconform
- **Deployment Verification:** Automated deployment to Kind cluster with rollout checks
- **Smoke Testing:** Automated health and version endpoint verification

## CI/CD Pipeline

The pipeline is designed to fail early on quality/security/policy issues before any deployment step runs.

### Pipeline Stages

1. **Code Quality** - `ruff` linting, `mypy` type checking, `pytest` unit tests
2. **Build** - Docker image creation
3. **Security** - Trivy vulnerability scanning with SARIF upload
4. **Validation** - Kubeconform Kubernetes manifest validation
5. **Policy** - Conftest/OPA policy enforcement (Rego rules)
6. **Deploy** - Helm deployment to Kind cluster
7. **Verify** - Rollout status check and smoke tests

## Quick Start

### Run Locally (Python)

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

# Start the application
uvicorn app.main:app --reload
```

**Verify:**
```bash
curl http://localhost:8000/health
curl http://localhost:8000/version
```

### Run Locally (Docker)

```bash
# Build the image
docker build -t local/secure-gitops-k8s-pipeline:dev .

# Run the container
docker run --rm -p 8000:8000 local/secure-gitops-k8s-pipeline:dev
```

**Verify:**
```bash
curl http://localhost:8000/health
curl http://localhost:8000/version
```

### Kubernetes (Kind + Helm) — Optional Local Demo

**Requirements:** `docker`, `kind`, `kubectl`, `helm`

```bash
# Create Kind cluster
kind create cluster --name demo

# Build and load image into Kind
docker build -t local/secure-gitops-k8s-pipeline:dev .
kind load docker-image local/secure-gitops-k8s-pipeline:dev --name demo

# Deploy with Helm
helm upgrade --install demo chart/secure-gitops-k8s-pipeline \
  --set image.repository=local/secure-gitops-k8s-pipeline \
  --set image.tag=dev

# Wait for rollout
kubectl rollout status deployment/demo --timeout=180s

# Port forward to access the service
kubectl port-forward svc/demo 8000:8000
```

**Verify:**
```bash
curl http://localhost:8000/health
curl http://localhost:8000/version
```

**Cleanup:**
```bash
kind delete cluster --name demo
```

## Repository Structure

```
.
├── app/                      # FastAPI application
│   ├── __init__.py
│   └── main.py              # Health and version endpoints
├── tests/                    # pytest unit tests
│   ├── __init__.py
│   └── test_main.py
├── chart/                    # Helm chart
│   └── secure-gitops-k8s-pipeline/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           └── service.yaml
├── policy/                   # OPA/Rego policies
│   └── deployment.rego      # Conftest policy checks
├── .github/
│   └── workflows/
│       └── ci.yml           # GitHub Actions CI pipeline
├── Dockerfile               # Multi-stage Docker build
├── requirements.txt         # Python dependencies
├── requirements-dev.txt     # Development dependencies
├── PORTFOLIO.md             # Portfolio documentation
└── README.md                # This file
```

## Technologies Used

- **Language:** Python 3.12
- **Framework:** FastAPI
- **Testing:** pytest, mypy, ruff
- **Container:** Docker
- **Orchestration:** Kubernetes, Helm
- **CI/CD:** GitHub Actions
- **Security:** Trivy
- **Policy:** OPA/Conftest
- **Tools:** Kind, kubeconform

## Notes (Real Issue Fixed)

During development, the deployment was stuck due to `CreateContainerConfigError`:

- **Root Cause:** `runAsNonRoot: true` could not be verified when the container user is not numeric (text username `appuser`)
- **Fix:** Set `runAsUser: 1000` in the pod security context so Kubernetes can verify the container runs as non-root
- **Files Changed:**
  - `chart/secure-gitops-k8s-pipeline/templates/deployment.yaml` - Added `runAsUser: 1000`
  - `chart/secure-gitops-k8s-pipeline/templates/deployment.yaml` - Added `imagePullPolicy: IfNotPresent` for Kind compatibility

## Security Features

- **Non-root container:** Runs as UID 1000 (appuser)
- **Security context:**
  - `runAsNonRoot: true`
  - `allowPrivilegeEscalation: false`
  - `privileged: false`
- **Vulnerability scanning:** Trivy scans for CRITICAL and HIGH vulnerabilities
- **Policy enforcement:** OPA/Conftest validates Kubernetes manifests against security policies

## CI Workflow

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs on:
- Pull requests
- Pushes to `main` branch

All quality gates, security checks, and policy validations must pass before deployment proceeds.