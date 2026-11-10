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
    const ws = new WebSocket(page.webSocketDebuggerUrl);
    await new Promise((res, rej) => {
      ws.addEventListener('open', res);
      ws.addEventListener('error', rej);
    });

    await sendCdp(ws, 'Page.enable');
    await sendCdp(ws, 'Emulation.setDeviceMetricsOverride', {
      width: 1440,
      height: 900,
      deviceScaleFactor: 1,
      mobile: false
    });

    console.log('Waiting for landing page to render...');
    await sleep(6000);

    // Click "Features" button (around x: 620, y: 31)
    console.log('Scrolling with mouseWheel...');
    for (let i = 0; i < 8; i++) {
      await sendCdp(ws, 'Input.dispatchMouseEvent', {
        type: 'mouseWheel',
        x: 720,
        y: 450,
        deltaX: 0,
        deltaY: 300
      });
      await sleep(150);
    }
    await sleep(1500);

    const shotFeatures = await sendCdp(ws, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(OUTPUT_DIR, '02_landing_features.png'), Buffer.from(shotFeatures.data, 'base64'));
    console.log(`Saved 02_landing_features.png (${Math.round(shotFeatures.data.length / 1024)} KB)`);

    for (let i = 0; i < 12; i++) {
      await sendCdp(ws, 'Input.dispatchMouseEvent', {
        type: 'mouseWheel',
        x: 720,
        y: 450,
        deltaX: 0,
        deltaY: 300
      });
      await sleep(150);
    }
    await sleep(1500);

    const shotArch = await sendCdp(ws, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(OUTPUT_DIR, '03_landing_architecture.png'), Buffer.from(shotArch.data, 'base64'));
    console.log(`Saved 03_landing_architecture.png (${Math.round(shotArch.data.length / 1024)} KB)`);

    for (let i = 0; i < 20; i++) {
      await sendCdp(ws, 'Input.dispatchMouseEvent', {
        type: 'mouseWheel',
        x: 720,
        y: 450,
        deltaX: 0,
        deltaY: 400
      });
      await sleep(150);
    }
    await sleep(1500);

    const shotFooter = await sendCdp(ws, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(OUTPUT_DIR, '04_landing_footer.png'), Buffer.from(shotFooter.data, 'base64'));
    console.log(`Saved 04_landing_footer.png (${Math.round(shotFooter.data.length / 1024)} KB)`);

    ws.close();
  } catch (e) {
    console.error(e);
  } finally {
    chrome.kill();
    console.log('Finished wheel captures.');
  }
}

main();
