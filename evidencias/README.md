# Evidências — nomes dos ficheiros (guardar em evidencias/prints/)

Formato: `figNN-descricao.png` (print da janela inteira, com data/hora e URL visíveis).

| Ficheiro | O que mostra |
|---|---|
| fig01-repositorio.png | Estrutura de ficheiros no GitHub |
| fig02-pipeline-grafo.png | Run com os 5 jobs (vista do grafo) |
| fig03-build.png | Log do job 1 – Build |
| fig04-testes.png | Log do job 2 – 4 testes aprovados |
| fig05-trivy-vulneravel.png | Relatório Trivy com lodash 4.17.15 (Summary) |
| fig06-npm-audit.png | Relatório npm audit (Summary) |
| fig07-gate-falhou.png | Job 3 vermelho (gate bloqueou) |
| fig08-commit-correcao.png | Diff do package.json (correção) |
| fig09-pipeline-verde.png | Run verde de ponta a ponta |
| fig10-imagem-docker.png | Log do job 4 + `docker images` |
| fig11-ghcr.png | Pacote publicado no GHCR |
| fig12-docker-ps-healthy.png | `docker ps` com contentor healthy |
| fig13-app-navegador.png | Aplicação em localhost:3000 |
| fig14-app-atualizada.png | Mensagem nova após alteração + novo run |

Logs gerados por `scripts/local-check.sh` ficam em `evidencias/logs/`.
