const FALLBACK_STATUS = {
  status: "unknown",
  javaAddress: "Not configured",
  bedrockAddress: "Not configured",
  bedrockPort: "",
  players: { online: 0, max: 0 },
  lastChecked: null,
  responseMs: null,
  version: "Paper 1.21.11",
  githubUrl: "#"
};

function bedrockAddressWithPort(data) {
  const address = data.bedrockAddress || FALLBACK_STATUS.bedrockAddress;
  const port = data.bedrockPort || "";
  if (!port || String(address).includes(":")) return address;
  return `${address}:${port}`;
}

const $ = (id) => document.getElementById(id);

function formatTime(value) {
  if (!value) return "No check recorded";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "No check recorded";
  return `Checked ${date.toLocaleString()}`;
}

function renderStatus(data) {
  const status = String(data.status || "unknown").toLowerCase();
  const statusText = status === "online" ? "Online" : status === "offline" ? "Offline" : "Checking";
  $("status").textContent = statusText;
  $("status-dot").className = `status-dot ${status}`;
  $("last-checked").textContent = formatTime(data.lastChecked);
  $("java-address").textContent = data.javaAddress || FALLBACK_STATUS.javaAddress;
  $("bedrock-address").textContent = bedrockAddressWithPort(data);
  $("players").textContent = data.players && Number.isFinite(data.players.online) ? `${data.players.online}/${data.players.max ?? "?"}` : "--";
  $("response").textContent = Number.isFinite(data.responseMs) ? `${data.responseMs} ms` : "--";
  $("updated").textContent = data.lastChecked ? new Date(data.lastChecked).toLocaleTimeString() : "--";
  $("version").textContent = data.version || FALLBACK_STATUS.version;
  $("github-link").href = data.githubUrl || "#";
}

async function loadStatus() {
  try {
    const response = await fetch(`status.json?cacheBust=${Date.now()}`, { cache: "no-store" });
    if (!response.ok) throw new Error(`Status request failed: ${response.status}`);
    renderStatus(await response.json());
  } catch (error) {
    renderStatus({ ...FALLBACK_STATUS, status: "offline" });
    console.error("Unable to load server status", error);
  }
}

document.querySelectorAll("[data-copy-target]").forEach((button) => {
  button.addEventListener("click", async () => {
    const value = $(button.dataset.copyTarget).textContent.trim();
    if (!value || value === "Not configured") return;
    try {
      await navigator.clipboard.writeText(value);
      $("toast").textContent = "Address copied";
      $("toast").classList.add("visible");
      window.setTimeout(() => $("toast").classList.remove("visible"), 1500);
    } catch {
      $("toast").textContent = value;
      $("toast").classList.add("visible");
      window.setTimeout(() => $("toast").classList.remove("visible"), 2500);
    }
  });
});

loadStatus();
window.setInterval(loadStatus, 60_000);
