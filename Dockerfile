# syntax=docker/dockerfile:1.7
# =============================================================================
# OSDO Scanner — Imagen oficial con todas las herramientas DevSecOps
# Publicada en: ghcr.io/opensecdevops/osdo-scanner
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Python tools installer
# -----------------------------------------------------------------------------
FROM python:3.12-slim AS python-tools

ARG SEMGREP_VERSION=1.90.0
ARG CHECKOV_VERSION=3.2.258
ARG BANDIT_VERSION=1.8.0
ARG SAFETY_VERSION=3.2.8

RUN pip install --no-cache-dir \
    semgrep==${SEMGREP_VERSION} \
    checkov==${CHECKOV_VERSION} \
    bandit==${BANDIT_VERSION} \
    safety==${SAFETY_VERSION}

# -----------------------------------------------------------------------------
# Stage 2: Go binary tools installer
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS binary-tools

ARG GITLEAKS_VERSION=8.21.2
ARG TRIVY_VERSION=0.57.1
ARG GRYPE_VERSION=0.87.0
ARG OSV_VERSION=1.9.2
ARG HADOLINT_VERSION=2.12.0
ARG SYFT_VERSION=1.14.2
ARG COSIGN_VERSION=2.4.1
ARG TRUFFLEHOG_VERSION=3.82.6
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates tar gzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tools

# Detectar arquitectura (amd64 / arm64)
RUN ARCH=${TARGETARCH:-amd64}; \
    \
    # Gitleaks
    curl -sSfL "https://github.com/zricethezav/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${ARCH}.tar.gz" | tar -xz gitleaks && \
    \
    # Trivy
    curl -sSfL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-$([ "$ARCH" = "arm64" ] && echo "ARM64" || echo "64bit").tar.gz" | tar -xz trivy && \
    \
    # Grype
    curl -sSfL "https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_${ARCH}.tar.gz" | tar -xz grype && \
    \
    # OSV-Scanner
    curl -sSfL -o osv-scanner "https://github.com/google/osv-scanner/releases/download/v${OSV_VERSION}/osv-scanner_linux_${ARCH}" && chmod +x osv-scanner && \
    \
    # Hadolint
    curl -sSfL -o hadolint "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "x86_64")" && chmod +x hadolint && \
    \
    # Syft
    curl -sSfL "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_${ARCH}.tar.gz" | tar -xz syft && \
    \
    # Cosign
    curl -sSfL -o cosign "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-${ARCH}" && chmod +x cosign && \
    \
    # TruffleHog
    curl -sSfL "https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_${ARCH}.tar.gz" | tar -xz trufflehog && \
    \
    chmod +x /tools/*

# -----------------------------------------------------------------------------
# Stage 3: Node.js + @osdo/cli
# -----------------------------------------------------------------------------
FROM node:22-slim AS node-tools

RUN npm install -g @osdo/cli@latest --omit=dev 2>/dev/null || \
    echo "OSDO CLI no publicado aún — se usará el binario local"

# -----------------------------------------------------------------------------
# Stage 4: Runtime final
# -----------------------------------------------------------------------------
FROM ubuntu:24.04

LABEL org.opencontainers.image.title="OSDO Scanner" \
      org.opencontainers.image.description="Imagen oficial OSDO con todas las herramientas de seguridad y el CLI" \
      org.opencontainers.image.url="https://github.com/opensecdevops/osdo-scanner" \
      org.opencontainers.image.source="https://github.com/opensecdevops/osdo-scanner" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="OpenSecDevOps"

# Dependencias de runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git curl python3 python3-pip nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# Copiar herramientas binarias
COPY --from=binary-tools /tools/ /usr/local/bin/

# Copiar herramientas Python
COPY --from=python-tools /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=python-tools /usr/local/bin/semgrep /usr/local/bin/semgrep
COPY --from=python-tools /usr/local/bin/checkov /usr/local/bin/checkov
COPY --from=python-tools /usr/local/bin/bandit /usr/local/bin/bandit
COPY --from=python-tools /usr/local/bin/safety /usr/local/bin/safety

# Copiar Node.js + @osdo/cli
COPY --from=node-tools /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node-tools /usr/local/bin/node /usr/local/bin/
COPY --from=node-tools /usr/local/bin/osdo /usr/local/bin/ 2>/dev/null || true

# Copiar entrypoint y directorio de trabajo
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

# Crear usuario no-root para scans
RUN groupadd -r osdo && useradd -r -g osdo -s /bin/bash osdo && \
    mkdir -p /workspace/.osdo && \
    chown -R osdo:osdo /workspace

USER osdo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["--help"]
