/**
 * ============================================================================
 *  src/app.js  —  Definição da aplicação Web (rotas e lógica de negócio)
 * ============================================================================
 *
 *  O QUE FAZ
 *    Cria e devolve uma aplicação Express com 3 rotas:
 *      GET /            -> página HTML simples (serve para a "alteração de código"
 *                          visível na demonstração: mudar APP_MESSAGE e fazer push).
 *      GET /health      -> responde {"status":"ok"}; usado pelo HEALTHCHECK do
 *                          Docker, pelo script de deploy e pelos testes.
 *      GET /api/greet   -> devolve uma saudação; usa o pacote lodash.
 *
 *  PORQUÊ ESTÁ SEPARADO DO server.js
 *    Este ficheiro só CONSTRÓI a app e NÃO abre nenhuma porta de rede. Assim, os
 *    testes (test/app.test.js) conseguem importar a app e arrancá-la numa porta
 *    aleatória sem conflitos. O ficheiro server.js é que a põe a "ouvir".
 *
 *  ⚠️  VULNERABILIDADE PROPOSITADA (para o Security Scan)
 *    O pacote "lodash" é usado aqui e está fixado na versão 4.17.15 no
 *    package.json. Essa versão tem CVEs conhecidos (ex.: CVE-2020-8203,
 *    CVE-2021-23337). O código DESTE ficheiro está correto — o problema está na
 *    DEPENDÊNCIA desatualizada, que é exatamente o que ferramentas SCA
 *    (Software Composition Analysis) como o Trivy e o "npm audit" detetam.
 *    Detalhes e correção: docs/02-ANALISE-SEGURANCA.md
 * ============================================================================
 */

'use strict'; // Modo estrito: apanha erros comuns (ex.: variáveis não declaradas).

// --- Importações -----------------------------------------------------------
// express: framework que trata de pedidos HTTP e rotas.
const express = require('express');
// lodash (convencionalmente "_"): biblioteca de utilitários. É AQUI que entra a
// dependência vulnerável. Usamos apenas _.capitalize e _.escape (inofensivos),
// mas o scanner avisa na mesma porque a versão instalada é a problemática.
const _ = require('lodash');

// --- Constantes de conteúdo --------------------------------------------------
// ALTERAR ESTA LINHA É A "ALTERAÇÃO SIMPLES NO CÓDIGO" DA DEMONSTRAÇÃO:
// muda o texto, faz commit + push e vê a pipeline arrancar sozinha e o contentor
// novo mostrar a mensagem atualizada.
const APP_MESSAGE = 'Pipeline CI/CD segura em funcionamento — versão 1.0';

// Nome da empresa fictícia do cenário do trabalho (aparece na página inicial).
const COMPANY = 'TechSecure Solutions';

/**
 * createApp — fábrica da aplicação.
 * Uma "fábrica" (função que devolve a app) em vez de uma app global permite criar
 * instâncias novas e isoladas em cada teste.
 *
 * @returns {import('express').Express} aplicação Express pronta a ser ligada a uma porta
 */
function createApp() {
  const app = express();

  // Esconde o cabeçalho "X-Powered-By: Express". Boa prática de hardening:
  // não anunciar a tecnologia ajuda a dificultar ataques dirigidos.
  app.disable('x-powered-by');

  // ROTA 1 — Página inicial -------------------------------------------------
  app.get('/', (req, res) => {
    // res.type('html') define Content-Type: text/html.
    // Usamos template literal (``) para montar o HTML numa só string.
    res.type('html').send(`<!doctype html>
<html lang="pt">
  <head><meta charset="utf-8"><title>${COMPANY}</title></head>
  <body style="font-family: sans-serif; max-width: 40rem; margin: 3rem auto;">
    <h1>${COMPANY}</h1>
    <p>${APP_MESSAGE}</p>
    <p><a href="/health">/health</a> · <a href="/api/greet?name=equipa">/api/greet?name=equipa</a></p>
  </body>
</html>`);
  });

  // ROTA 2 — Health check ---------------------------------------------------
  // Rota leve que só diz "estou vivo". NÃO deve aceder a bases de dados nem a
  // serviços externos: tem de responder depressa e de forma fiável, porque o
  // Docker (HEALTHCHECK) e o script de deploy a chamam repetidamente.
  app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  // ROTA 3 — Saudação (usa lodash) -------------------------------------------
  // Exemplo: GET /api/greet?name=ana  ->  {"message":"Olá, Ana!"}
  app.get('/api/greet', (req, res) => {
    // req.query.name pode ser string, array ou undefined (ex.: ?name=a&name=b dá array).
    // Validar o tipo evita comportamentos inesperados: só aceitamos string.
    const raw = typeof req.query.name === 'string' ? req.query.name : 'visitante';

    // Limita o tamanho a 30 caracteres: nunca confiar em input do utilizador sem limites.
    const limited = raw.trim().slice(0, 30);

    // _.capitalize -> "ANA" vira "Ana". _.escape -> converte <, >, &, ", ' em
    // entidades HTML (defesa em profundidade contra XSS caso este valor venha
    // a ser colocado numa página HTML no futuro).
    const name = _.escape(_.capitalize(limited));

    res.json({ message: `Olá, ${name}!` });
  });

  return app;
}

// Exportamos a fábrica para o server.js (produção) e para os testes.
module.exports = { createApp };
