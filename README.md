# TechSecure Solutions · Pipeline CI/CD segura (AP II – DevSecOps)

Prova de conceito de uma esteira **CI/CD com segurança integrada** para a empresa fictícia TechSecure Solutions: a cada `push`, o código é construído, testado, analisado quanto a vulnerabilidades, empacotado numa imagem Docker e colocado a correr num contentor.

```
Código ─► Build ─► Teste ─► Análise de Segurança ─► Imagem Docker ─► Deploy Automático ─► Contentor
(push)    npm ci    npm test   Trivy + npm audit      docker build      scripts/deploy.sh    :3000
                               └─ gate bloqueia se há HIGH/CRITICAL
```

## Equipa
| Nome | Papel |
|---|---|
| Leonardo Gerlach | Contentores e deploy |
| Leonardo Gerlach | Validação local |
| Henrique Fried | Aplicação e testes |
| Guilherme Borges | Pipeline e GitHub |
| Henrique Fried e Guilherme Borges | Segurança e documentação |

## Estrutura do repositório
```
.
├── .github/workflows/main.yml   # Pipeline (5 jobs: build, teste, segurança, imagem, deploy)
├── src/
│   ├── app.js                   # Rotas da aplicação (usa lodash – versão vulnerável PROPOSITADA)
│   └── server.js                # Arranque do servidor e encerramento limpo
├── test/app.test.js             # Testes automatizados (node:test)
├── scripts/deploy.sh            # Substitui o contentor pela versão nova + smoke test
├── Dockerfile                   # Receita da imagem (Node 22 Alpine, utilizador não-root, HEALTHCHECK)
├── .dockerignore / .gitignore
├── package.json / package-lock.json
└── docs/
    ├── 01-DIVISAO-TAREFAS.md
    ├── 02-ANALISE-SEGURANCA.md
    └── 03-RELATORIO-ESTRUTURA.md
```

## Tecnologias
GitHub + GitHub Actions · Node.js 22 + Express · `node:test` · Docker · GitHub Container Registry (GHCR) · **Trivy** e **npm audit** · Alpine Linux.

## Começar (uma só vez)
1. Instalar [Node.js LTS](https://nodejs.org). Na pasta do projeto: `npm install` — **gera o `package-lock.json`**. Fazer commit dele (a pipeline e o Dockerfile precisam deste ficheiro e o Trivy lê-o).
2. Criar o repositório no GitHub e fazer `push` para a branch `main`.
3. Em **Actions** ver a pipeline a correr sozinha.

## Correr localmente
```bash
npm ci && npm run build && npm test     # build + testes
npm start                               # http://localhost:3000

docker build -t techsecure-app .        # imagem
bash scripts/deploy.sh techsecure-app   # contentor em http://localhost:3000
```

## A pipeline
| # | Job | Etapa | Falha quando… |
|---|---|---|---|
| 1 | Build | Build | dependências não instalam ou há erro de sintaxe |
| 2 | Teste | Teste | algum teste falha |
| 3 | Análise de Segurança | Security Scan | Trivy/npm audit acham HIGH/CRITICAL (se o gate estiver ativo) |
| 4 | Construção da Imagem | Imagem | o `docker build`/push falha (só na `main`) |
| 5 | Deploy | Deploy → Contentor | o contentor não fica *healthy* ou o smoke test falha |

**Variáveis do repositório** (Settings → Secrets and variables → Actions → *Variables*):

| Variável | Efeito |
|---|---|
| `SECURITY_GATE=false` | O scan só **relata**; não bloqueia a pipeline |
| `DEPLOY_RUNNER=self-hosted` | O deploy corre no PC da equipa e o contentor **fica a correr** lá |

**Runner auto-alojado (opcional, para a demonstração):** Settings → Actions → Runners → *New self-hosted runner* e seguir os passos no PC com Docker Desktop (Linux/macOS/WSL2 recomendados; em Windows o *step* usa Git Bash). Sem esta variável, o deploy é validado num servidor do GitHub, mas o contentor desaparece no fim do job.

## ⚠️ Vulnerabilidade propositada
`package.json` fixa **`lodash@4.17.15`**, que tem CVEs conhecidos (p. ex. CVE-2021-23337 e CVE-2020-8203, severidade HIGH). Serve para o scan ter algo a detetar.
- Análise completa e correção: [`docs/02-ANALISE-SEGURANCA.md`](docs/02-ANALISE-SEGURANCA.md)
- **Corrigir:** `npm install lodash@latest` → commit → push → o gate passa.

## Alteração de código e novo deploy
Editar a constante `APP_MESSAGE` em `src/app.js` → `git commit` → `git push` → a pipeline arranca sozinha e, no fim, `http://localhost:3000` mostra a mensagem nova.

## Evidências a guardar
Pipeline completa · log do build · testes · relatório Trivy/npm audit · gate a falhar e depois a passar · imagem Docker (`docker images`, GHCR) · `docker ps` com contentor *healthy* · aplicação no browser. (Lista numerada em `docs/03-RELATORIO-ESTRUTURA.md`.)

## Problemas frequentes
| Sintoma | Causa / solução |
|---|---|
| `npm ci` falha no job *Build* | Falta o `package-lock.json` no repositório (correr `npm install` e fazer commit) |
| Trivy: `TOOMANYREQUESTS` | Limite ao descarregar a base de dados; repetir o run |
| `invalid reference format` na imagem | Nome do repositório com maiúsculas (a pipeline já converte para minúsculas) |
| `denied` ao publicar no GHCR | Falta a permissão `packages: write` (já definida no job *image*) |
| Pipeline vermelha no *Gate* | É o comportamento esperado com o lodash vulnerável: corrigir a dependência |
| Contentor não aparece no meu PC | O deploy correu num servidor do GitHub; usar `DEPLOY_RUNNER=self-hosted` |
