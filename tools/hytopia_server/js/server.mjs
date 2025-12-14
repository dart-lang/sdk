import { Server } from "@hytopia/sdk";

// Minimal example — adapt to the real @hytopia/sdk API.
async function main() {
  const port = process.env.PORT ? Number(process.env.PORT) : 8080;

  // `Server` constructor and methods below are illustrative.
  const server = new Server({ port });

  // If the SDK uses an event emitter style:
  if (typeof server.on === 'function') {
    server.on('request', (req, res) => {
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('Hello from Hytopia Server (JS example)\n');
    });
  }

  // Example: handle player join using hypothetical SDK hooks.
  // Many game/server SDKs provide either a specific method like
  // `onPlayerJoin` or an event name such as 'playerJoin'. Handle both.
  if (typeof server.onPlayerJoin === 'function') {
    server.onPlayerJoin((player) => {
      if (typeof player.sendMessage === 'function') {
        player.sendMessage('Welcome Shadow Army!');
      } else {
        console.log('Player joined (no sendMessage):', player);
      }
    });
  } else if (typeof server.on === 'function') {
    server.on('playerJoin', (player) => {
      if (player && typeof player.sendMessage === 'function') {
        player.sendMessage('Welcome Shadow Army!');
      } else {
        console.log('Player joined (event):', player);
      }
    });
  }

  // If the SDK exposes an async start method:
  if (typeof server.start === 'function') {
    await server.start();
    console.log(`Hytopia Server running on port ${port}`);
    return;
  }

  // Fallback: if constructor already binds, just log.
  console.log(`Hytopia Server instance created (port ${port}).`);
}

main().catch((e) => {
  console.error('Failed to start Hytopia Server example:', e);
  process.exit(1);
});
