#!/usr/bin/env bash
# ==============================================================================
#  scripts/deploy.sh — Deploy automático: põe a imagem nova a correr num contentor
# ==============================================================================
#  ETAPA DA PIPELINE: "Deploy Automático → Contentor" (job 5 do main.yml).
#
#  USO:   bash scripts/deploy.sh <referência-da-imagem>
#  EX.:   bash scripts/deploy.sh ghcr.io/o-teu-grupo/techsecure-cicd:abc1234
#
#  O QUE FAZ (por esta ordem):
#    1. Descarrega (pull) a imagem do registo (GHCR).
#    2. Remove o contentor ANTIGO, se existir (é o que "atualiza" a aplicação).
#    3. Arranca o contentor NOVO em segundo plano.
#    4. Espera que o HEALTHCHECK do Docker dê "healthy".
#    5. Faz um pedido HTTP à aplicação (smoke test) e mostra o estado.
#    Se qualquer passo falhar, o script termina com erro => o job fica vermelho.
#
#  Também funciona na tua máquina:  bash scripts/deploy.sh techsecure-app
#  (sem pull se a imagem for local; ver nota no passo 1).
# ==============================================================================

# set -e : termina logo se algum comando falhar (não continuar "às cegas").
# set -u : erro se usarmos uma variável não definida (apanha gralhas).
# set -o pipefail : um erro dentro de um "pipe" (a | b) também conta como erro.
set -euo pipefail

# $1 = 1.º argumento. A sintaxe ${1:?mensagem} obriga a que exista; senão mostra a mensagem e sai.
IMAGE_REF="${1:?Falta a referência da imagem. Uso: bash scripts/deploy.sh <imagem>}"

# Valores configuráveis por variável de ambiente, com padrão sensato.
# O nome FIXO do contentor é o que nos permite encontrar e substituir a versão antiga.
CONTAINER_NAME="${CONTAINER_NAME:-techsecure-app}"
# Porta do ANFITRIÃO onde a app fica acessível (dentro do contentor é sempre 3000).
HOST_PORT="${HOST_PORT:-3000}"

echo "==> [1/5] A descarregar a imagem: ${IMAGE_REF}"
# "|| echo ..." : se o pull falhar (ex.: imagem só existe localmente), seguimos em
# frente e o "docker run" abaixo falhará de forma clara se a imagem não existir.
docker pull "${IMAGE_REF}" || echo "    (pull falhou; a tentar usar imagem local)"

echo "==> [2/5] A remover o contentor antigo (se existir)"
# "docker ps -a" lista TODOS os contentores (também os parados).
# "grep -qx" procura o nome EXATO sem imprimir nada; o "if" usa só o resultado.
if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
  # "rm -f" para (SIGTERM/SIGKILL) e remove num só comando.
  docker rm -f "${CONTAINER_NAME}"
fi

echo "==> [3/5] A arrancar o contentor novo"
# -d                      : segundo plano (detached).
# --name                  : nome fixo (ver acima).
# --restart unless-stopped: o Docker volta a arrancá-lo após um reinício do PC/Docker.
# -p HOST:3000            : liga a porta do anfitrião à porta 3000 do contentor.
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p "${HOST_PORT}:3000" \
  "${IMAGE_REF}"

echo "==> [4/5] A esperar que o contentor fique saudável (máx. 60 s)"
STATUS="starting"
for _ in $(seq 1 30); do                         # 30 tentativas x 2 s = 60 s
  # Lê o estado do HEALTHCHECK definido no Dockerfile. Se ainda não existir, assume "starting".
  STATUS="$(docker inspect --format '{{.State.Health.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo starting)"
  [ "${STATUS}" = "healthy" ] && break           # saudável -> sai do ciclo
  sleep 2
done

if [ "${STATUS}" != "healthy" ]; then
  echo "ERRO: o contentor não ficou saudável (estado: ${STATUS}). Últimos logs:"
  docker logs --tail 50 "${CONTAINER_NAME}"
  exit 1                                          # falha => o job da pipeline fica vermelho
fi

echo "==> [5/5] Smoke test e evidências"
# curl --fail devolve erro se o HTTP não for 2xx; --silent --show-error limpa o output.
echo "GET /health  -> $(curl --fail --silent --show-error "http://127.0.0.1:${HOST_PORT}/health")"
echo "GET /api/greet -> $(curl --fail --silent --show-error "http://127.0.0.1:${HOST_PORT}/api/greet?name=pipeline")"
echo
echo "--- docker ps (EVIDÊNCIA: contentor em execução) ---"
docker ps --filter "name=${CONTAINER_NAME}"
echo
echo "DEPLOY CONCLUÍDO: aplicação disponível em http://localhost:${HOST_PORT}"
