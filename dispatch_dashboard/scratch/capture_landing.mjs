import { spawn } from 'child_process';
import http from 'http';
import fs from 'fs';
import path from 'path';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9222;
const OUTPUT_DIR = "C:/Users/Ruhama/.gemini/antigravity/brain/32f56c3d-e968-4b59-96e7-cd73ebe9f589/scratch/screenshots";

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

function sendCdp(ws, method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = Math.floor(Math.random() * 1000000);
    const handler = (event) => {
      try {
        const msg = JSON.parse(event.data);
        if (msg.id === id) {
          ws.removeEventListener('message', handler);
          if (msg.error) reject(msg.error);
          else resolve(msg.result);
        }
      } catch (e) {}
    };
    ws.addEventListener('message', handler);
    ws.send(JSON.stringify({ id, method, params }));
  });
}

async function main() {
  console.log('Launching Chrome headless...');
  const chrome = spawn(CHROME_PATH, [
    '--headless=new',
    `--remote-debugging-port=${PORT}`,
    '--disable-gpu',
    '--no-first-run',
    '--window-size=1440,900',
    '--user-data-dir=C:\\Users\\Ruhama\\.gemini\\antigravity\\brain\\32f56c3d-e968-4b59-96e7-cd73ebe9f589\\scratch\\chrome_user_data_capture',
    'http://localhost:5050/'
  ]);

  await sleep(2500);

  try {
    const pages = await fetchJson(`http://127.0.0.1:${PORT}/json/list`);
    const page = pages.find(p => p.type === 'page');
    if (!page) throw new Error('No page found');

    const ws = new WebSocket(page.webSocketDebuggerUrl);
    await new Promise((res, rej) => {
      ws.addEventListener('open', res);
      ws.addEventListener('error', rej);
    });

    await sendCdp(ws, 'Page.enable');
    await sendCdp(ws, 'Runtime.enable');
    await sendCdp(ws, 'Emulation.setDeviceMetricsOverride', {
      width: 1440,
      height: 900,
      deviceScaleFactor: 1,
      mobile: false
    });

    console.log('Waiting 14 seconds for initial Flutter landing page render...');
    await sleep(14000);

    const shot1 = await sendCdp(ws, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(OUTPUT_DIR, '01_landing_top.png'), Buffer.from(shot1.data, 'base64'));
    console.log(`Saved 01_landing_top.png (${Math.round(shot1.data.length / 1024)} KB)`);

    // Scroll to features
    await sendCdp(ws, 'Runtime.evaluate', { expression: `window.scrollBy({ top: 900, behavior: 'smooth' });` });
    await sleep(2000);
    const shot2 = await sendCdp(ws, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(OUTPUT_DIR, '02_landing_features.png'), Buffer.from(shot2.data, 'base64'));
    console.log(`Saved 02_landing_features.png (${Math.round(shot2.data.length / 1024)} KB)`);

    // Scroll to architecture
    await sendCdp(ws, 'Runtime.evaluate', { expression: `window.scrollBy({ top: 900, behavior: 'smooth' });` });
    await sleep(2000);
    const shot3 = await sendCdp(ws, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(OUTPUT_DIR, '03_landing_architecture.png'), Buffer.from(shot3.data, 'base64'));
    console.log(`Saved 03_landing_architecture.png (${Math.round(shot3.data.length / 1024)} KB)`);

    // Scroll to footer
    await sendCdp(ws, 'Runtime.evaluate', { expression: `window.scrollTo({ top: 99999, behavior: 'smooth' });` });
    await sleep(2000);
    const shot4 = await sendCdp(ws, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(OUTPUT_DIR, '04_landing_footer.png'), Buffer.from(shot4.data, 'base64'));
    console.log(`Saved 04_landing_footer.png (${Math.round(shot4.data.length / 1024)} KB)`);

    // Navigate to login via location.hash
    await sendCdp(ws, 'Runtime.evaluate', { expression: `window.location.hash = '#/login';` });
    await sleep(3000);
    const shot5 = await sendCdp(ws, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(OUTPUT_DIR, '05_login.png'), Buffer.from(shot5.data, 'base64'));
    console.log(`Saved 05_login.png (${Math.round(shot5.data.length / 1024)} KB)`);

    // Navigate to register via location.hash
    await sendCdp(ws, 'Runtime.evaluate', { expression: `window.location.hash = '#/register';` });
    await sleep(3000);
    const shot6 = await sendCdp(ws, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(OUTPUT_DIR, '06_register.png'), Buffer.from(shot6.data, 'base64'));
    console.log(`Saved 06_register.png (${Math.round(shot6.data.length / 1024)} KB)`);

    ws.close();
  } catch (e) {
    console.error(e);
  } finally {
    chrome.kill();
    console.log('Done.');
  }
}

main();
