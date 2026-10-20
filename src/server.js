/**
 * ============================================================================
 *  src/server.js  —  Ponto de entrada: abre a porta de rede e serve a app
 * ============================================================================
 *
 *  É este o ficheiro que o comando "npm start" e o CMD do Dockerfile executam.
 *  Responsabilidades (e só estas): ler a configuração, ligar a app a uma porta e
 *  encerrar de forma limpa quando o Docker pedir.
 * ============================================================================
 */

'use strict';

const { createApp } = require('./app');

// PORT vem de uma variável de ambiente (padrão 12-factor: configuração fora do
// código). Se não existir, usamos 3000. Number() converte o texto em número.
const PORT = Number(process.env.PORT) || 3000;

// Escutamos em 0.0.0.0 (todas as interfaces). DENTRO de um contentor isto é
// obrigatório: se escutássemos só em 127.0.0.1, o mapeamento de portas do Docker
// (-p 3000:3000) não conseguiria alcançar a aplicação a partir do anfitrião.
const server = createApp().listen(PORT, '0.0.0.0', () => {
  console.log(`[TechSecure] Aplicação a escutar na porta ${PORT}`);
});

// --- Encerramento limpo (graceful shutdown) -----------------------------------
// "docker stop" envia SIGTERM ao processo principal. Um processo Node que corre
// como PID 1 num contentor IGNORA o SIGTERM se não tiver um handler — e o Docker
// acaba por o matar à força ao fim de 10 s. Com este handler terminamos logo e bem
// (isto acelera cada novo deploy, que começa por parar o contentor antigo).
function shutdown(signal) {
  console.log(`[TechSecure] Recebido ${signal}; a encerrar...`);
  server.close(() => process.exit(0)); // para de aceitar ligações e sai
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT')); // Ctrl+C no terminal
