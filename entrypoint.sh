#!/bin/bash
# OSDO Scanner — Entrypoint
# Wrapper que invoca el CLI de OSDO o las herramientas directamente

set -euo pipefail

# Si el primer argumento es un comando de herramienta conocida, invocarlo directamente
case "${1:-}" in
  semgrep|gitleaks|trivy|grype|osv-scanner|hadolint|syft|cosign|trufflehog|checkov|bandit|safety)
    exec "$@"
    ;;
  osdo|"")
    # Invocar OSDO CLI
    exec osdo "${@:2}"
    ;;
  *)
    # Pasar directamente al CLI de OSDO
    exec osdo "$@"
    ;;
esac
