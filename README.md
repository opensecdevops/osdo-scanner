# OSDO Scanner

Imagen Docker oficial de OSDO con todas las herramientas DevSecOps pre-instaladas.

[![Build](https://github.com/opensecdevops/osdo-scanner/actions/workflows/build.yml/badge.svg)](https://github.com/opensecdevops/osdo-scanner/actions/workflows/build.yml)
[![GHCR](https://img.shields.io/badge/GHCR-osdo--scanner-blue)](https://ghcr.io/opensecdevops/osdo-scanner)

## Herramientas incluidas

| Herramienta | Uso | Categoría |
|-------------|-----|-----------|
| [Semgrep](https://semgrep.dev) | SAST multi-lenguaje | Análisis estático |
| [Gitleaks](https://gitleaks.io) | Detección de secretos | Secrets |
| [TruffleHog](https://github.com/trufflesecurity/trufflehog) | Escaneo profundo de secretos | Secrets |
| [Trivy](https://trivy.dev) | Contenedores, IaC, SBOM | Múltiple |
| [Grype](https://github.com/anchore/grype) | CVEs en dependencias | SCA |
| [OSV-Scanner](https://google.github.io/osv-scanner/) | Base de datos OSV | SCA |
| [Syft](https://github.com/anchore/syft) | Generación SBOM (SPDX + CycloneDX) | SBOM |
| [Cosign](https://github.com/sigstore/cosign) | Firma de contenedores | Supply Chain |
| [Hadolint](https://hadolint.github.io/hadolint/) | Lint de Dockerfiles | IaC |
| [Checkov](https://www.checkov.io) | IaC (Terraform, K8s, CF) | IaC |
| [Bandit](https://bandit.readthedocs.io) | SAST Python | Análisis estático |
| [Safety](https://safetycli.com) | SCA Python | SCA |
| [@osdo/cli](https://npmjs.com/package/@osdo/cli) | CLI de OSDO | Orquestación |

## Uso rápido

```bash
# Escanear el directorio actual
docker run --rm -v $(pwd):/workspace ghcr.io/opensecdevops/osdo-scanner osdo scan

# Auditar workflows de CI/CD
docker run --rm -v $(pwd):/workspace ghcr.io/opensecdevops/osdo-scanner osdo audit

# Usar una herramienta individual
docker run --rm -v $(pwd):/workspace ghcr.io/opensecdevops/osdo-scanner semgrep --config auto /workspace
docker run --rm -v $(pwd):/workspace ghcr.io/opensecdevops/osdo-scanner trivy fs /workspace
docker run --rm -v $(pwd):/workspace ghcr.io/opensecdevops/osdo-scanner gitleaks detect --source /workspace
```

## Uso en GitHub Actions

```yaml
jobs:
  security-scan:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/opensecdevops/osdo-scanner:latest
    steps:
      - uses: actions/checkout@v4
      - name: OSDO Full Scan
        run: osdo scan --type all --path .
      - name: OSDO Audit
        run: osdo audit --format markdown
```

## Uso como Dev Container

```json
// .devcontainer/devcontainer.json
{
  "image": "ghcr.io/opensecdevops/osdo-scanner:latest",
  "customizations": {
    "vscode": {
      "extensions": ["opensecdevops.osdo-security"]
    }
  }
}
```

## Actualización de herramientas

Las versiones se gestionan en [`tools.json`](./tools.json). Cada lunes, el workflow [`update-tools.yml`](./.github/workflows/update-tools.yml) verifica si hay nuevas versiones y abre un PR automáticamente.

La imagen también se reconstruye semanalmente (domingos) para capturar actualizaciones de la imagen base Ubuntu.

## Versionado

Las imágenes se publican con estos tags:
- `latest` — siempre apunta al último build de `main`
- `sha-<commit>` — versión inmutable por commit
- `YYYYMMDD` — builds agendados semanales
- `v1.x.x` — releases versionados

## Licencia

Apache 2.0 — ver [LICENSE](./LICENSE)
