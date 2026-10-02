#!/usr/bin/env node
/*
 * Minimal zero-dependency static server for testing the web build locally.
 *
 *   node tool/serve_web.js [port]
 *
 * Service workers and PWA install prompts only work on localhost or HTTPS,
 * which is why this is useful instead of opening build/web/index.html
 * directly from the file system.
 */

const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..', 'build', 'web');
const port = Number(process.argv[2] || 8080);

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.bin': 'application/octet-stream',
  '.frag': 'text/plain; charset=utf-8',
  '.map': 'application/json; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
};

function send(res, status, body, type) {
  res.writeHead(status, {
    'Content-Type': type || 'text/plain; charset=utf-8',
    'Cache-Control': 'no-cache',
    'Service-Worker-Allowed': '/',
  });
  res.end(body);
}

http
  .createServer((req, res) => {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const decoded = decodeURIComponent(url.pathname);
    const target = path.join(root, decoded);

    // Refuse anything that escapes the build directory.
    if (!target.startsWith(root)) {
      send(res, 403, 'Forbidden');
      return;
    }

    let file = target;
    if (fs.existsSync(file) && fs.statSync(file).isDirectory()) {
      file = path.join(file, 'index.html');
    }

    if (!fs.existsSync(file)) {
      const shell = path.join(root, 'index.html');
      if (fs.existsSync(shell)) {
        send(res, 200, fs.readFileSync(shell), TYPES['.html']);
        return;
      }
      send(res, 404, 'Not found');
      return;
    }

    send(res, 200, fs.readFileSync(file), TYPES[path.extname(file).toLowerCase()]);
  })
  .listen(port, () => {
    console.log(`Serving ${root}`);
    console.log(`Open http://localhost:${port}`);
  });