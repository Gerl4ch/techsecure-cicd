# 03 · Estrutura do trabalho escrito (PDF ou Word)

> Segue exatamente a lista de conteúdos exigida no enunciado da AP II. Em cada secção: **o que escrever** e **de onde tirar o material**.

## Capa e integrantes
Instituição, disciplina (DevSecOps), título (*Esteira CI/CD segura para a TechSecure Solutions*), data de entrega (19/10/2026), tabela com nome, RA/n.º de aluno e **papel de cada elemento** (usem a tabela de `docs/01`).

## 1. Objetivo
1–2 parágrafos: construir uma pipeline CI/CD que automatize *Código → Build → Teste → Análise de Segurança → Imagem → Deploy → Contentor*, com segurança integrada (*shift left*), para o cenário fictício da TechSecure Solutions (reduzir erros de implantação e incorporar segurança no ciclo de desenvolvimento).

## 2. Arquitetura
- Diagrama do fluxo (copiem o do README) e explicação de cada componente: repositório GitHub, GitHub Actions (runners), GHCR (registo), Docker, runner auto-alojado (se usado), contentor final.
- Decisões de desenho: *gate* de segurança configurável, um job por etapa, deploy só na `main`.

## 3. Aplicação escolhida
API/página Node.js + Express com 3 rotas (`/`, `/health`, `/api/greet`). Porquê simples: o foco é a esteira, não a aplicação. Referir a **dependência vulnerável propositada** (lodash 4.17.15).

## 4. Tecnologias utilizadas
Tabela: GitHub (versionamento), GitHub Actions (CI/CD), Node.js 22 + Express (aplicação), `node:test` (testes), Docker (contentorização), GHCR (registo), **Trivy** e **npm audit** (segurança), Alpine Linux (imagem base). Para cada uma: função e razão da escolha.

## 5. Descrição da pipeline
Um subtítulo por job do `.github/workflows/main.yml`: gatilho, o que faz, o que a faz falhar e que etapa do enunciado cobre. Incluir o conceito de `needs` (dependência entre jobs) e a política de permissões mínimas. Mencionar a decisão de não usar a action de terceiros do Trivy (ver `docs/02`, secção 7).

## 6. Dockerfile
Colar o ficheiro e explicar as boas práticas: base Alpine fixada, cópia dos manifestos antes do código (cache), `npm ci --omit=dev`, utilizador sem privilégios, `HEALTHCHECK`, `CMD` em forma *exec*.

## 7. Ferramenta de segurança
Trivy e npm audit: o que são (SCA), o que analisam (`package-lock.json`), parâmetros usados (`--severity`, `--ignore-unfixed`, `--exit-code`) e o conceito de *quality gate*.

## 8. Análise de segurança e resultados
- **Achado**: vulnerabilidade, componente, severidade, correção — conteúdo de `docs/02-ANALISE-SEGURANCA.md` (secções 2–5).
- **Resultados**: tabela *antes/depois* (nº de achados HIGH/CRITICAL, estado do gate, estado do deploy), tempos de execução dos jobs, testes aprovados.

## 9. Evidências
Cada figura numerada, legendada e referida no texto.

| Fig. | O que capturar | Onde |
|---|---|---|
| 1 | Repositório com a estrutura de ficheiros | GitHub > Code |
| 2 | Pipeline com os 5 jobs (vista do grafo) | Actions > run |
| 3 | Log do job *Build* | Actions > 1 - Build |
| 4 | Saída dos 4 testes a passar | Actions > 2 - Teste |
| 5 | **Relatório Trivy com o lodash vulnerável** | Run > Summary |
| 6 | Relatório `npm audit` | Run > Summary |
| 7 | **Gate de segurança a falhar** (pipeline vermelha) | Actions > 3 - Segurança |
| 8 | Commit da correção (diff do `package.json`) | GitHub > Commits |
| 9 | Pipeline verde de ponta a ponta | Actions > run |
| 10 | Log do build da imagem e `docker images` | Actions > 4 – Imagem / PC local |
| 11 | Imagem publicada no GHCR | GitHub > Packages |
| 12 | `docker ps` com contentor *healthy* | Terminal |
| 13 | Aplicação no browser em `localhost:3000` | Browser |
| 14 | Aplicação atualizada após a alteração de código + novo run | Browser + Actions |

## 10. Dificuldades encontradas
Escrevam as **reais**. Candidatas comuns: `npm ci` a falhar por falta de `package-lock.json`; nome da imagem com maiúsculas; permissões do GHCR (`packages: write`); limite de pedidos ao descarregar a base de dados do Trivy (*TOOMANYREQUESTS* — repetir o run); Docker Desktop pesado em PCs modestos; `localhost` vs `127.0.0.1` no *health check*; deploy num runner do GitHub não deixa o contentor a correr (solução: runner auto-alojado).

## 11. Conclusão
O que foi atingido face ao objetivo, o valor de automatizar a segurança (feedback em minutos, bloqueio de versões vulneráveis antes do deploy), limitações (SCA não prova exploração; só analisa dependências, não o código próprio) e melhorias futuras (Semgrep/SAST, OWASP ZAP/DAST, Dependabot, scan da imagem final, assinatura de imagens, ambientes de *staging*).

## Anexos e referências
Código completo (ou link do repositório), `main.yml`, `Dockerfile`, avisos CVE consultados (NVD / GitHub Advisories), documentação oficial do Trivy, Docker e GitHub Actions.
