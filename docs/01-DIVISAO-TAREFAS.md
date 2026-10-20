# 01 · Divisão de tarefas (PC potente vs. PC modesto)

> Pensado para **5 elementos**. Se forem menos, juntem papéis (indicado no fim). Os nomes e o tipo de PC são para preencher.

## Quem faz o quê

| Papel | Tipo de PC | Responsável | O que faz | Entrega |
|---|---|---|---|---|
| **A · Contentores e deploy** | 🖥️ Potente | _(nome)_ | Instalar Docker Desktop, construir e correr a imagem localmente, validar o `Dockerfile`, **instalar o runner auto-alojado** e ser o PC da demonstração | Contentor a correr em `localhost:3000`, capturas de `docker images` / `docker ps` |
| **B · Validação local** | 🖥️ Potente | _(nome)_ | Correr **toda** a cadeia à mão antes de cada push (ver "Simular a pipeline localmente"), correr o Trivy local sobre o código **e sobre a imagem**, ensaiar a demonstração obrigatória do enunciado | Confirmação "verde" antes de cada merge, relatório Trivy da imagem |
| **C · Aplicação e testes** | 💻 Modesto | _(nome)_ | Editar `src/` e `test/` num editor leve (VS Code / Notepad++), gerar o `package-lock.json` (só precisa de Node), fazer a correção da vulnerabilidade | App + testes a passar; `package-lock.json` no repositório |
| **D · Pipeline e GitHub** | 💻 Modesto | _(nome)_ | Criar o repositório, editar `main.yml` **no browser** (tecla `.` abre o github.dev), configurar variáveis `SECURITY_GATE` e `DEPLOY_RUNNER`, ler logs do Actions | Pipeline verde; capturas do Actions |
| **E · Segurança e documentação** | 💻 Modesto | _(nome)_ | Investigar os CVEs (NVD / GitHub Advisories), escrever `docs/02`, `README.md` e o relatório, **recolher e numerar as evidências** | Relatório PDF/Word, README final, pasta de evidências |

### Porquê esta separação
- **PC potente** (recomendado ≥ 16 GB RAM, virtualização ativa/WSL2): o Docker Desktop corre uma VM Linux e consome 2–4 GB só em repouso; builds de imagem e o runner auto-alojado também. Quem tem esta máquina fica com o que **exige Docker**.
- **PC modesto**: tudo o resto corre num browser ou num editor de texto. Para o `package-lock.json` basta ter o Node.js instalado (`npm install` demora segundos). Se nem isso for possível, usem **GitHub Codespaces** (ambiente na nuvem, abre a partir do repositório) e gerem lá o ficheiro.

## Ordem de trabalho (dependências)

1. **D** cria o repositório e dá acesso a todos → 2. **C** faz o primeiro commit (código + `package-lock.json`) → 3. **D** confirma que a pipeline arranca → 4. **A** configura o runner e valida o contentor → 5. **E** captura a evidência do scan **vulnerável** → 6. **C** corrige a dependência → 7. **B** valida → 8. **E** captura a evidência do scan **limpo** e fecha o relatório.

## Simular a pipeline localmente (papel B — PC potente)

```bash
npm ci                         # Build: instala a partir do lockfile
npm run build                  # Build: verifica sintaxe
npm test                       # Teste
npm audit --audit-level=high   # Segurança 1
docker run --rm -v "$PWD:/project" -w /project ghcr.io/aquasecurity/trivy:0.69.3 \
  fs --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed .   # Segurança 2
docker build -t techsecure-app .                                   # Imagem
bash scripts/deploy.sh techsecure-app                              # Deploy -> contentor
```
(Em Windows, usem o Git Bash ou o WSL2 para estes comandos.)

## Plano até à entrega (19/10/2026)

| Quando | Objetivo |
|---|---|
| **Sábado 17/10** | Repositório criado, código + lockfile no GitHub, pipeline a correr, **primeiro scan com o lodash vulnerável capturado** (pipeline vermelha no gate = evidência), runner configurado se for usado |
| **Domingo 18/10** | Correção da dependência, pipeline verde de ponta a ponta, contentor a correr, **todas as capturas feitas**, README fechado, relatório escrito |
| **Segunda 19/10 (manhã)** | Revisão cruzada do relatório, teste final da alteração de código + push (ver README), exportar PDF, entregar |

## Boas práticas de equipa
- Trabalhar em **branches** (`feature/…`) e juntar via **Pull Request**: a pipeline corre Build+Teste+Segurança em cada PR (sem deploy).
- Mensagens de commit claras (`feat:`, `fix:`, `docs:`) e cada pessoa a fazer commits com o **seu** utilizador — o histórico é evidência de que todos participaram.
- Se forem **menos de 5**: C+E juntam-se (aplicação + documentação) e A+B juntam-se; D fica a quem tiver mais jeito para GitHub.
