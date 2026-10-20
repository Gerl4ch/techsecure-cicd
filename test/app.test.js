/**
 * ============================================================================
 *  test/app.test.js  —  Testes automatizados (etapa "Teste" da pipeline)
 * ============================================================================
 *
 *  COMO FUNCIONA
 *    Usamos o test runner NATIVO do Node ("node:test"), por isso não há
 *    dependências de teste para instalar (menos superfície de ataque e menos
 *    CVEs no relatório de segurança). O "npm test" executa este ficheiro.
 *
 *  ESTRATÉGIA (teste de integração leve)
 *    1. Antes dos testes: arrancamos a app real numa porta ALEATÓRIA (porta 0 =
 *       "sistema operativo, escolhe uma livre"), para nunca colidir com nada.
 *    2. Cada teste faz um pedido HTTP verdadeiro (fetch) e verifica a resposta.
 *    3. Depois dos testes: fechamos o servidor, para o processo poder terminar.
 *
 *  IMPORTANTE PARA A PIPELINE
 *    Se uma asserção falhar, "npm test" devolve código de saída != 0 e o job
 *    "Teste" fica vermelho; como os jobs seguintes dependem dele (needs), a
 *    análise de segurança, a imagem e o deploy NÃO chegam a correr. É isto que
 *    impede código partido de chegar a produção.
 * ============================================================================
 */

'use strict';

// "test" regista um caso de teste; "before"/"after" são ganchos de preparação e limpeza.
const { test, before, after } = require('node:test');
// "assert/strict" compara valores com igualdade estrita (===) e dá mensagens claras.
const assert = require('node:assert/strict');
const { createApp } = require('../src/app');

let server;  // referência ao servidor HTTP, para o podermos fechar no fim
let baseUrl; // ex.: "http://127.0.0.1:54321" (a porta muda em cada execução)

// Corre UMA vez antes de todos os testes.
before(async () => {
  // Envolvemos o listen numa Promise para só continuar quando o servidor estiver pronto.
  server = await new Promise((resolve) => {
    const s = createApp().listen(0, '127.0.0.1', () => resolve(s));
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

// Corre UMA vez depois de todos os testes (mesmo que algum falhe).
after(async () => {
  // Fecha ligações "keep-alive" pendentes; sem isto o processo podia ficar preso.
  server.closeAllConnections?.();
  await new Promise((resolve) => server.close(resolve));
});

// TESTE 1 — a rota de saúde responde 200 e o JSON esperado.
test('GET /health devolve 200 e {"status":"ok"}', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { status: 'ok' });
});

// TESTE 2 — a página inicial é HTML e contém o nome da empresa.
test('GET / devolve HTML com o nome da empresa', async () => {
  const res = await fetch(`${baseUrl}/`);
  assert.equal(res.status, 200);
  assert.match(res.headers.get('content-type'), /text\/html/);
  assert.match(await res.text(), /TechSecure Solutions/);
});

// TESTE 3 — a lógica que usa lodash capitaliza o nome ("ANA" -> "Ana").
test('GET /api/greet?name=ANA devolve "Olá, Ana!"', async () => {
  const res = await fetch(`${baseUrl}/api/greet?name=ANA`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { message: 'Olá, Ana!' });
});

// TESTE 4 — segurança básica: caracteres HTML perigosos vêm escapados.
test('GET /api/greet escapa HTML no nome (defesa contra XSS)', async () => {
  const res = await fetch(`${baseUrl}/api/greet?name=${encodeURIComponent('<b>x</b>')}`);
  const body = await res.json();
  assert.ok(!body.message.includes('<b>'), 'a resposta não pode conter a tag <b> em bruto');
  assert.match(body.message, /&lt;/);
});
