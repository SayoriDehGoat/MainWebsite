// Minimal Minecraft RCON client. Reads rcon.host/port/password from
// server/server.properties (gitignored) so no credentials are committed.
//
// Usage: node scripts/rcon.mjs <command> [server.properties path]

import net from 'node:net';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const command = process.argv[2] || 'list';
const propsPath = process.argv[3] || path.join(scriptDir, '..', 'server', 'server.properties');

const props = {};
for (const line of fs.readFileSync(propsPath, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^([^#=]+)=(.*)$/);
    if (m) props[m[1].trim()] = m[2].trim();
}

const host = props['rcon.host'] || '127.0.0.1';
const port = parseInt(props['rcon.port'] || '25575', 10);
const password = props['rcon.password'] || '';

if (!password) {
    console.error('RCON is not enabled (rcon.password is empty in server.properties).');
    process.exit(1);
}

let buffer = Buffer.alloc(0);
let authed = false;
let loginId = null;

const socket = net.connect(port, host);

function packet(id, type, body) {
    const payload = Buffer.from(body + '\0', 'utf8');
    const len = 4 + 4 + payload.length + 2;
    const buf = Buffer.alloc(len + 4);
    buf.writeInt32LE(len, 0);
    buf.writeInt32LE(id, 4);
    buf.writeInt32LE(type, 8);
    payload.copy(buf, 12);
    return buf;
}

function send(type, body) {
    const id = Math.floor(Math.random() * 0x7fffffff);
    socket.write(packet(id, type, body));
    return id;
}

socket.on('connect', () => {
    loginId = send(3, password); // SERVERDATA_AUTH
});

socket.on('data', (chunk) => {
    buffer = Buffer.concat([buffer, chunk]);
    while (buffer.length >= 4) {
        const len = buffer.readInt32LE(0);
        if (buffer.length < len + 4) break;
        const id = buffer.readInt32LE(4);
        const type = buffer.readInt32LE(8);
        const body = buffer.subarray(12, 4 + len - 2).toString('utf8').replace(/\0+$/, '');
        buffer = buffer.subarray(len + 4);

        if (!authed && id === loginId && type === 2) {
            if (id === -1) {
                console.error('RCON authentication failed.');
                process.exit(1);
            }
            authed = true;
            send(2, command); // SERVERDATA_EXECCOMMAND
        } else if (authed && type === 0) {
            if (body.trim()) console.log(body);
            socket.end();
        }
    }
});

socket.on('error', (err) => {
    console.error(`RCON error: ${err.message}`);
    process.exit(1);
});

socket.setTimeout(10000, () => {
    console.error('RCON timed out. Is the server running with RCON enabled?');
    process.exit(1);
});
