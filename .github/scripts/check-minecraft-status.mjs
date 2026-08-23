import net from "node:net";
import dns from "node:dns/promises";
import fs from "node:fs";

const address = process.env.MC_JAVA_ADDRESS || "ireland-dis.gl.joinmc.link";
const separator = address.lastIndexOf(":") > address.indexOf("]") ? address.lastIndexOf(":") : -1;
const host = separator > -1 ? address.slice(0, separator).replace(/^\[|\]$/g, "") : address;
const configuredPort = separator > -1 ? Number(address.slice(separator + 1)) : null;
const timeoutMs = 7000;
const protocolVersion = 774;

async function resolveEndpoint() {
  if (configuredPort) return { host, port: configuredPort };
  try {
    const records = await dns.resolveSrv(`_minecraft._tcp.${host}`);
    const record = records.sort((left, right) => left.priority - right.priority)[0];
    if (record) return { host: record.name.replace(/\.$/, ""), port: record.port };
  } catch {
    // A host without SRV falls back to Minecraft's default Java port.
  }
  return { host, port: 25565 };
}

function encodeVarInt(value) {
  const bytes = [];
  let unsigned = value >>> 0;
  do {
    let byte = unsigned & 0x7f;
    unsigned >>>= 7;
    if (unsigned) byte |= 0x80;
    bytes.push(byte);
  } while (unsigned);
  return Buffer.from(bytes);
}

function decodeVarInt(buffer, offset = 0) {
  let value = 0;
  let position = offset;
  for (let index = 0; index < 5; index += 1) {
    if (position >= buffer.length) return null;
    const byte = buffer[position++];
    value |= (byte & 0x7f) << (7 * index);
    if ((byte & 0x80) === 0) return { value, offset: position };
  }
  throw new Error("Invalid Minecraft VarInt");
}

function encodeString(value) {
  const data = Buffer.from(value, "utf8");
  return Buffer.concat([encodeVarInt(data.length), data]);
}

function readStatusPacket(buffer) {
  const packetLength = decodeVarInt(buffer);
  if (!packetLength) return null;
  if (buffer.length < packetLength.offset + packetLength.value) return null;

  const packet = buffer.subarray(packetLength.offset, packetLength.offset + packetLength.value);
  const packetId = decodeVarInt(packet);
  if (!packetId || packetId.value !== 0) throw new Error("Unexpected Minecraft status packet");
  const jsonLength = decodeVarInt(packet, packetId.offset);
  if (!jsonLength) return null;
  const jsonStart = jsonLength.offset;
  const jsonEnd = jsonStart + jsonLength.value;
  if (packet.length < jsonEnd) return null;
  return JSON.parse(packet.subarray(jsonStart, jsonEnd).toString("utf8"));
}

function ping(endpoint) {
  return new Promise((resolve) => {
    const started = Date.now();
    const socket = net.createConnection(endpoint);
    let response = Buffer.alloc(0);
    let settled = false;
    const finish = (result) => {
      if (settled) return;
      settled = true;
      socket.destroy();
      resolve(result);
    };
    const timer = setTimeout(() => finish({ online: false, responseMs: null }), timeoutMs);
    socket.on("error", () => {
      clearTimeout(timer);
      finish({ online: false, responseMs: null });
    });
    socket.on("data", (chunk) => {
      response = Buffer.concat([response, chunk]);
      try {
        const json = readStatusPacket(response);
        if (!json) return;
        clearTimeout(timer);
        finish({
          online: true,
          responseMs: Date.now() - started,
          players: {
            online: Number(json.players?.online || 0),
            max: Number(json.players?.max || 0)
          },
          version: json.version?.name || "Paper 1.21.11 + Geyser"
        });
      } catch (error) {
        clearTimeout(timer);
        console.error("Minecraft status response parse failed:", error instanceof Error ? error.message : error);
        finish({ online: false, responseMs: null });
      }
    });
    socket.on("connect", () => {
      const handshake = Buffer.concat([
        encodeVarInt(0x00),
        encodeVarInt(protocolVersion),
        encodeString(endpoint.host),
        Buffer.from([(endpoint.port >> 8) & 0xff, endpoint.port & 0xff]),
        encodeVarInt(1)
      ]);
      const handshakePacket = Buffer.concat([encodeVarInt(handshake.length), handshake]);
      const request = Buffer.from([0x01, 0x00]);
      socket.write(Buffer.concat([handshakePacket, request]));
    });
  });
}

const endpoint = await resolveEndpoint();
const result = await ping(endpoint);
const path = "status.json";
const current = JSON.parse(fs.readFileSync(path, "utf8"));
const nextStatus = result.online ? "online" : "offline";
const nextPlayers = result.players || { online: 0, max: 0 };
const nextVersion = result.version || current.version;
const bedrockOverride = process.env.MC_BEDROCK_ADDRESS || "";
const bedrockSeparator = bedrockOverride.lastIndexOf(":") > bedrockOverride.indexOf("]") ? bedrockOverride.lastIndexOf(":") : -1;
const nextBedrockAddress = bedrockSeparator > -1 ? bedrockOverride.slice(0, bedrockSeparator) : (bedrockOverride || current.bedrockAddress);
const nextBedrockPort = bedrockSeparator > -1 ? bedrockOverride.slice(bedrockSeparator + 1) : (current.bedrockPort || "");
const meaningfulChange = current.status !== nextStatus
  || current.players?.online !== nextPlayers.online
  || current.players?.max !== nextPlayers.max
  || current.version !== nextVersion
  || current.javaAddress !== address
  || current.bedrockAddress !== nextBedrockAddress
  || current.bedrockPort !== nextBedrockPort;
const next = {
  ...current,
  status: nextStatus,
  javaAddress: address,
  bedrockAddress: nextBedrockAddress,
  bedrockPort: nextBedrockPort,
  players: nextPlayers,
  lastChecked: meaningfulChange ? new Date().toISOString() : current.lastChecked,
  responseMs: meaningfulChange ? result.responseMs : current.responseMs,
  version: nextVersion,
  githubUrl: process.env.GITHUB_REPO_URL || current.githubUrl
};
fs.writeFileSync(path, `${JSON.stringify(next, null, 2)}\n`);
console.log(JSON.stringify(next));
