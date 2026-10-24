// Run with Node 22+ and a locally installed Chrome (no npm dependencies).
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const http = require("node:http");
const { spawn } = require("node:child_process");

async function main() {
  const root = path.resolve(__dirname, "..");
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), "troday-browser-"));
  const chromePath = process.env.CHROME_PATH || "C:/Program Files/Google/Chrome/Application/chrome.exe";
  const server = http.createServer((req, res) => {
    const file = path.resolve(root, `.${decodeURIComponent(new URL(req.url, "http://localhost").pathname)}`);
    const relative = path.relative(root, file);
    if (relative.startsWith("..") || path.isAbsolute(relative)) { res.writeHead(403).end(); return; }
    const target = file === root ? path.join(root, "index.html") : file;
    if (!fs.existsSync(target) || !fs.statSync(target).isFile()) { res.writeHead(404).end(); return; }
    const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8", ".webp": "image/webp", ".png": "image/png" };
    res.setHeader("Content-Type", types[path.extname(target)] || "application/octet-stream");
    fs.createReadStream(target).pipe(res);
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  let chrome, socket;
  try {
    chrome = spawn(chromePath, ["--headless=new", "--no-sandbox", "--disable-gpu", "--no-first-run", "--no-default-browser-check", "--disable-background-networking", "--remote-debugging-port=0", `--user-data-dir=${profile}`, "about:blank"], { windowsHide: true, stdio: ["ignore", "ignore", "pipe"] });
    const endpoint = await new Promise((resolve, reject) => {
      let output = "";
      const timer = setTimeout(() => reject(new Error(`Chrome startup timed out: ${output.slice(-1000)}`)), 20000);
      chrome.on("error", (error) => { clearTimeout(timer); reject(error); });
      chrome.stderr.on("data", (chunk) => {
        output += chunk.toString(); const match = output.match(/DevTools listening on (ws:\/\/\S+)/);
        if (match) { clearTimeout(timer); resolve(match[1]); }
      });
    });
    socket = new WebSocket(endpoint);
    await new Promise((resolve, reject) => { socket.onopen = resolve; socket.onerror = reject; });
    let sequence = 0;
    const pending = new Map(); const errors = [];
    socket.onmessage = ({ data }) => {
      const message = JSON.parse(data);
      if (message.id) {
        const request = pending.get(message.id); if (!request) return;
        pending.delete(message.id); clearTimeout(request.timer);
        if (message.error) request.reject(new Error(JSON.stringify(message.error))); else request.resolve(message.result);
      } else if (message.method === "Runtime.exceptionThrown") errors.push(message.params.exceptionDetails.text + ": " + (message.params.exceptionDetails.exception?.description || ""));
    };
    const call = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
      const id = ++sequence;
      const timer = setTimeout(() => { pending.delete(id); reject(new Error(`Timed out: ${method}`)); }, 15000);
      pending.set(id, { resolve, reject, timer }); socket.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
    });
    const { targetInfos } = await call("Target.getTargets");
    const target = targetInfos.find((item) => item.type === "page");
    const { sessionId } = await call("Target.attachToTarget", { targetId: target.targetId, flatten: true });
    const page = (method, params) => call(method, params, sessionId);
    const evaluate = async (expression) => {
      const result = await page("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true });
      if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text);
      return result.result.value;
    };
    await page("Page.enable"); await page("Runtime.enable");
    await page("Emulation.setTimezoneOverride", { timezoneId: "America/Los_Angeles" });
    await page("Emulation.setDeviceMetricsOverride", { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
    await page("Page.addScriptToEvaluateOnNewDocument", { source: `const NativeDate = Date; window.Date = class extends NativeDate { constructor(...args) { super(...(args.length ? args : [NativeDate.parse('2026-10-24T03:00:00Z')])); } static now() { return NativeDate.parse('2026-10-24T03:00:00Z'); } };` });
    await page("Page.navigate", { url: `http://127.0.0.1:${server.address().port}/index.html?role=landlord&view=residents` });
    for (let attempt = 0; attempt < 100; attempt++) {
      if (await evaluate("Boolean(window.__troday)")) break;
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    assert.equal(await evaluate("Boolean(window.__troday)"), true);
    await evaluate(`document.querySelector('[data-action="move-out"][data-id="k2:o2"]').click()`);
    assert.equal(await evaluate(`document.querySelector('#app-dialog').open && document.querySelector('[name="successorId"]').value === 'o3'`), true);
    await evaluate(`document.querySelector('[name="consent"]').checked = true; document.querySelector('form[data-form="representative-handover"]').requestSubmit()`);
    assert.equal(await evaluate(`__troday.getState().contracts.find(c => c.id === 'k2').tenantId`), "ngoc");
    assert.equal(await evaluate(`document.querySelector('#app-main').textContent.includes('Đỗ Bích Ngọc') && !document.querySelector('[data-action="move-out"][data-id="k2:o2"]')`), true);
    await evaluate(`__troday.action('contract-detail', 'k2'); document.querySelector('[data-action="representative-history"]').click()`);
    assert.equal(await evaluate(`document.querySelector('#dialog-body').textContent.includes('Phạm Thu Mai') && document.querySelector('#dialog-body').textContent.includes('Đỗ Bích Ngọc')`), true);
    await evaluate(`document.querySelector('[data-action="close-dialog"]').click(); __troday.reset(); __troday.action('switch-role', 'landlord'); __troday.action('navigate', 'residents'); document.querySelector('[data-action="approve-join"]').click()`);
    assert.equal(await evaluate(`__troday.getState().joinRequests[0].status`), "APPROVED");
    assert.equal(await evaluate(`document.querySelector('#app-main').textContent.includes('Giữ đến')`), true);

    // Build a two-person contract using actual rendered forms and browser FormData.
    await evaluate(`__troday.action('switch-role', 'tenant'); __troday.action('agree-rent', 'v2'); __troday.action('switch-role', 'landlord'); __troday.action('open-contract', 'v2')`);
    await evaluate(`document.querySelector('[name="members"]').value = 'Bạn cùng phòng, 0123456789'; document.querySelector('form[data-form="create-contract"]').requestSubmit()`);
    const newId = await evaluate(`__troday.getState().selectedContract`);
    assert.equal(await evaluate(`__troday.getState().contracts.find(c => c.id === ${JSON.stringify(newId)}).members.length`), 2);
    await evaluate(`__troday.action('switch-role', 'tenant'); __troday.action('confirm-contract', ${JSON.stringify(newId)}); __troday.action('switch-role', 'landlord'); __troday.action('confirm-move-in', ${JSON.stringify(newId)})`);
    assert.equal(await evaluate(`document.querySelectorAll('[name="memberIds"]:checked').length`), 2);
    await page("Emulation.setDeviceMetricsOverride", { width: 390, height: 844, deviceScaleFactor: 1, mobile: true });
    assert.equal(await evaluate("document.documentElement.scrollWidth <= window.innerWidth"), true);
    await evaluate(`document.querySelector('form[data-form="move-in"]').requestSubmit()`);
    assert.equal(await evaluate(`__troday.getState().contracts.find(c => c.id === ${JSON.stringify(newId)}).members.every(m => m.status === 'ACTIVE')`), true);

    // Calendar uses Vietnam time while Chrome itself runs in Los Angeles time.
    await evaluate(`__troday.action('open-appointment', '')`);
    assert.equal(await evaluate(`document.querySelector('[name="date"]').value`), "2026-10-24");
    assert.equal(await evaluate(`document.querySelector('[name="time"]').value`), "10:30");
    await evaluate(`document.querySelector('[name="roomId"]').value = 'r1'; document.querySelector('form[data-form="appointment"]').requestSubmit()`);
    assert.equal(await evaluate(`__troday.getState().viewings.at(-1).startsAt`), "2026-10-24T03:30:00.000Z");
    const viewingId = await evaluate(`__troday.getState().viewings.at(-1).id`);
    await evaluate(`__troday.action('cancel-viewing', ${JSON.stringify(viewingId)}); document.querySelector('[name="reason"]').value = 'Đổi kế hoạch'; document.querySelector('form[data-form="cancel-viewing"]').requestSubmit()`);
    assert.equal(await evaluate(`__troday.getState().viewings.at(-1).status`), "CANCELLED");

    await evaluate(`__troday.action('cancel-contract', 'k1'); document.querySelector('[name="reason"]').value = 'Hai bên hủy'; document.querySelector('form[data-form="cancel-contract"]').requestSubmit(); __troday.action('switch-role', 'tenant'); __troday.action('navigate', 'viewings')`);
    await evaluate(`document.querySelector('[data-action="withdraw-rent"][data-id="v3"]').click()`);
    assert.equal(await evaluate(`__troday.getState().viewings.find(v => v.id === 'v3').decision`), "WITHDRAWN");
    assert.deepEqual(errors, []);
    console.log("Browser smoke passed: representative handover and history, approval hold, two-person contract and move-in, mobile layout, UTC+7 calendar, cancellation and withdrawal; no runtime exceptions.");
    await call("Browser.close");
  } finally {
    socket?.close(); chrome?.kill();
    await new Promise((resolve) => server.close(resolve));
    // This is the unique temporary profile created above, never the user's browser profile.
    const absoluteProfile = path.resolve(profile);
    if (path.dirname(absoluteProfile) === path.resolve(os.tmpdir()) && path.basename(absoluteProfile).startsWith("troday-browser-")) {
      fs.rmSync(absoluteProfile, { recursive: true, force: true, maxRetries: 10, retryDelay: 100 });
    }
  }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
