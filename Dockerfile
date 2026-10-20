# ==============================================================================
#  Dockerfile — Receita para construir a imagem Docker da aplicação
# ==============================================================================
#  ETAPA DA PIPELINE: "Construção da Imagem" (job 4 do main.yml).
#  COMO SE USA LOCALMENTE:   docker build -t techsecure-app .
#                            docker run -d -p 3000:3000 --name techsecure-app techsecure-app
#
#  Cada instrução cria uma "camada" (layer) em cache. A ORDEM importa: o que muda
#  menos vem primeiro, para o Docker reaproveitar o cache e as builds serem rápidas.
# ==============================================================================

# FROM — define a imagem BASE sobre a qual construímos.
#   * node:22-alpine = Node.js 22 (LTS) sobre Alpine Linux.
#   * Porquê Alpine: imagem muito pequena (~50 MB vs ~400 MB), logo menos pacotes
#     do sistema operativo e menos vulnerabilidades possíveis (superfície de ataque menor).
#   * Boa prática: fixar a versão (22) em vez de "latest", para builds reprodutíveis.
FROM node:22-alpine

# ENV NODE_ENV=production — diz ao Node e ao Express que estamos em produção
#   (ativa otimizações e evita instalar/usar ferramentas de desenvolvimento).
ENV NODE_ENV=production

# WORKDIR — define a pasta de trabalho DENTRO do contentor (é criada se não existir).
#   Todas as instruções seguintes (COPY, RUN, CMD) passam a ser relativas a /app.
WORKDIR /app

# COPY (1.º, só os manifestos de dependências) — copiamos package.json e
#   package-lock.json ANTES do código. Assim, enquanto as dependências não
#   mudarem, o Docker reutiliza o cache do passo "npm ci" abaixo, mesmo que o
#   código mude (que é o caso de quase todos os commits). Poupa minutos por build.
#   NOTA: se o package-lock.json não estiver no repositório este passo FALHA, e
#   ainda bem — o lockfile garante as mesmas versões exatas em todas as builds
#   (é também o ficheiro que o Trivy lê para detetar vulnerabilidades).
COPY package.json package-lock.json ./

# RUN npm ci --omit=dev — instala as dependências.
#   * "npm ci" instala EXATAMENTE o que está no lockfile (mais seguro e
#     reprodutível que "npm install").
#   * "--omit=dev" ignora devDependencies: a imagem final leva só o necessário.
#   * "npm cache clean --force" apaga a cache do npm para a imagem ficar mais leve.
RUN npm ci --omit=dev && npm cache clean --force

# COPY (2.º, o código-fonte) — só agora copiamos o código. A pasta test/ e outros
#   ficheiros desnecessários ficam de fora (ver também o .dockerignore).
COPY src ./src

# USER node — a partir daqui o processo corre como o utilizador "node" (sem
#   privilégios), que já vem na imagem base. Por defeito o Docker corre como root;
#   se alguém explorasse uma falha na app, teria root no contentor. Princípio do
#   menor privilégio: é uma das boas práticas que o Trivy/CIS Benchmarks recomendam.
USER node

# EXPOSE — documenta que a aplicação escuta na porta 3000. Não publica a porta
#   (isso é feito com "-p" no "docker run"); serve de documentação e para ferramentas.
EXPOSE 3000

# HEALTHCHECK — o Docker corre este comando a cada 10 s para saber se a app está
#   saudável (estado "healthy"/"unhealthy" em "docker ps"). O script de deploy
#   espera por "healthy" antes de dar o deploy como bem-sucedido.
#   * Usamos o próprio Node (fetch) para não depender de curl/wget na imagem.
#   * Usamos 127.0.0.1 e não "localhost": no Node 18+ "localhost" pode resolver
#     para IPv6 (::1), onde a app não escuta, e o teste falharia sem razão.
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

# CMD — comando que arranca quando o contentor inicia.
#   * Forma "exec" (array JSON): o Node passa a ser o processo principal (PID 1)
#     e recebe diretamente os sinais do Docker (SIGTERM no "docker stop"), que o
#     src/server.js trata para encerrar de forma limpa.
CMD ["node", "src/server.js"]
