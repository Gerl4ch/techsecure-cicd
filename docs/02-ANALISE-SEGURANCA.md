# 02 · Análise de segurança (texto base para o relatório)

> ⚠️ Os números de CVE e severidades abaixo são os **esperados** para `lodash@4.17.15`. O trabalho deve citar o que **o vosso scan realmente mostrou**: confirmem cada identificador e severidade no output do Trivy / `npm audit` e na base de avisos do GitHub antes de entregar.

## 1. O que foi introduzido propositadamente
A aplicação depende do pacote **lodash** fixado na versão **4.17.15** (`package.json`). É uma **dependência desatualizada com vulnerabilidades conhecidas**. O código da aplicação em si está correto; o risco vem de componente de terceiros — uma falha típica da categoria *Vulnerable and Outdated Components* (OWASP Top 10).

## 2. Componente afetado
| Campo | Valor |
|---|---|
| Pacote | `lodash` (biblioteca de utilitários JavaScript) |
| Versão instalada | `4.17.15` |
| Ficheiro onde é declarada | `package.json` / `package-lock.json` |
| Onde é usada | `src/app.js` (`_.capitalize`, `_.escape`) |
| Tipo de dependência | Direta (declarada por nós) |

## 3. Vulnerabilidades esperadas

| CVE | Problema | Severidade (CVSS) | Corrigido em |
|---|---|---|---|
| **CVE-2021-23337** | *Command injection* através de `_.template` | **High** (7.2) | 4.17.21 |
| **CVE-2020-8203** | *Prototype pollution* em `_.zipObjectDeep` | **High** (7.4) | 4.17.19 |
| CVE-2020-28500 | ReDoS (negação de serviço por expressão regular) em `toNumber`/`trim`/`trimEnd` | Medium (5.3) | 4.17.21 |

O scan pode listar **mais** achados (por exemplo avisos mais recentes sobre versões posteriores do lodash). Escolham para o relatório **o de maior severidade** e referenciem o identificador exato que a ferramenta mostrou.

**Sugestão de achado principal para o relatório:** CVE-2021-23337 (HIGH) — o `_.template` compila texto em código; se uma aplicação lhe passar texto controlado por um atacante, pode executar comandos no servidor.

### Nota de honestidade técnica (vale pontos no relatório)
A nossa app **não chama** `_.template` nem `_.zipObjectDeep`, logo a exploração direta **não é possível neste código**. O scanner SCA assinala a **presença** da versão vulnerável, não a *alcançabilidade* da função. Mesmo assim, corrige-se: basta uma futura alteração (ou outra dependência) passar a usar a função afetada.

## 4. Como foi detetado
- **Trivy** (`fs`, lê o `package-lock.json`) → tabela com Library, Vulnerability ID, Severity, Installed Version, **Fixed Version**.
- **npm audit** → lista o pacote, a gravidade e o comando de correção.
- Ambos correm automaticamente no job *3 – Análise de Segurança*; o relatório aparece no *Summary* do run e como artefacto `relatorios-seguranca`.

## 5. Correção / mitigação
**Opção A — atualizar (recomendada para a demonstração)**
```bash
npm install lodash@latest     # sobe para a versão 4.x mais recente (>= 4.17.21)
npm audit                     # confirmar que o achado desapareceu
git add package.json package-lock.json
git commit -m "fix(deps): atualizar lodash para versão sem CVEs HIGH"
git push
```
Confirmem na coluna **Fixed Version** do Trivy qual é a versão mínima segura e que a pipeline fica verde.

**Opção B — remover a dependência (melhor ainda):** `_.capitalize` e `_.escape` têm equivalentes simples em JavaScript nativo, logo o lodash pode sair (`npm uninstall lodash`) e a superfície de ataque diminui.

**Mitigações complementares (para a discussão):** gate de segurança na pipeline (já implementado), Dependabot/Renovate para PRs automáticos de atualização, `npm ci` com lockfile, imagem base mínima (Alpine) e execução como utilizador sem privilégios (já no `Dockerfile`).

## 6. Como demonstrar "antes" e "depois"
1. **Antes:** `SECURITY_GATE` vazio → o scan encontra o lodash 4.17.15 → o *Gate* **falha**, a imagem e o deploy não correm. (Captura: scan + gate vermelho.)
2. Aplicar a correção (secção 5) e fazer push.
3. **Depois:** o scan não reporta HIGH/CRITICAL → o gate passa → imagem → deploy → contentor. (Captura: pipeline toda verde.)

## 7. Decisão de segurança da própria pipeline (bónus para o relatório)
Em março de 2026 a cadeia de fornecimento do Trivy foi comprometida: foi publicada uma versão maliciosa (0.69.4) e a maioria das tags da action `aquasecurity/trivy-action` foi redirecionada para código que roubava credenciais. Por isso esta pipeline **não usa essa action**: corre o Trivy numa imagem **com versão fixada** (0.69.3, indicada como segura no aviso oficial) e só usa actions oficiais do GitHub (`actions/*`). Aviso: <https://github.com/aquasecurity/trivy/security/advisories/GHSA-69fq-xp46-6x23>. Boa prática adicional: fixar também as actions por *commit SHA*.
