#!/usr/bin/env bash
# ==============================================================================
#  scripts/local-check.sh — Corre localmente a MESMA cadeia da pipeline e guarda
#  os logs em evidencias/logs/ (evidência para o relatório).
#  USO:  bash scripts/local-check.sh [nome-da-imagem]      (padrão: techsecure-app)
#  Nota: com o lodash vulnerável, o Trivy e o npm audit devolvem código != 0.
#        Isso é ESPERADO (é o "antes"). O script continua até ao fim.
# ==============================================================================
set -uo pipefail
IMG="${1:-techsecure-app}"
OUT="evidencias/logs"
TRIVY_IMAGE="ghcr.io/aquasecurity/trivy:0.69.3"   # igual ao main.yml
mkdir -p "$OUT"
: > "$OUT/_resumo.txt"

step() {                       # step <nome-do-ficheiro> <comando...>
  local name="$1"; shift
  echo; echo "=================== $name ==================="
  { echo "# $(date '+%F %T') | comando: $*"; "$@"; } 2>&1 | tee "$OUT/$name.txt"
  local rc=${PIPESTATUS[0]}
  echo "$name -> exit code $rc" | tee -a "$OUT/_resumo.txt"
}

step 01-npm-ci          npm ci
step 02-npm-build       npm run build
step 03-npm-test        npm test
step 04-npm-audit       npm audit --audit-level=high
step 05-trivy           docker run --rm -v "$PWD:/project" -w /project "$TRIVY_IMAGE" \
                          fs --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed --no-progress .
step 06-docker-build    docker build -t "$IMG" .
step 07-docker-images   docker images
step 08-deploy          bash scripts/deploy.sh "$IMG"
step 09-docker-ps       docker ps --filter "name=techsecure-app"

echo; echo "===== RESUMO ====="; cat "$OUT/_resumo.txt"
