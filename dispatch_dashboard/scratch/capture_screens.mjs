import { spawn } from 'child_process';
import http from 'http';
import fs from 'fs';
import path from 'path';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9222;
const OUTPUT_DIR = "C:/Users/Ruhama/.gemini/antigravity/brain/32f56c3d-e968-4b59-96e7-cd73ebe9f589/scratch/screenshots";

if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

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
      } catch (e) {
        // ignore
      }
    };
    ws.addEventListener('message', handler);
    ws.send(JSON.stringify({ id, method, params }));
  });
}

async function waitForFlutter(ws, maxWait = 15000) {
  const start = Date.now();
  while (Date.now() - start < maxWait) {
    try {
      const res = await sendCdp(ws, 'Runtime.evaluate', {
        expression: `(function() {
          const view = document.querySelector('flutter-view, flt-glass-pane, flt-scene-host');
          return view !== null && document.body.innerText.length > 5;
        })()`,
        returnByValue: true
      });
      if (res.result && res.result.value === true) {
        return true;
      }
    } catch (e) {}
    await sleep(500);
  }
  return false;
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

    console.log('Connected to CDP WebSocket');
    await sendCdp(ws, 'Page.enable');
    await sendCdp(ws, 'Runtime.enable');
    await sendCdp(ws, 'Emulation.setDeviceMetricsOverride', {
      width: 1440,
      height: 900,
      deviceScaleFactor: 1,
      mobile: false
    });

    console.log('Warming up Flutter Web engine...');
    await sleep(6000);
    await waitForFlutter(ws, 12000);
    console.log('Flutter is loaded and active!');

    const captureSequence = [
      { name: '01_landing_top', url: 'http://localhost:5050/', scrollY: 0, wait: 2000 },
      { name: '02_landing_features', url: 'http://localhost:5050/', scrollY: 850, wait: 1500 },
      { name: '03_landing_architecture', url: 'http://localhost:5050/', scrollY: 1800, wait: 1500 },
      { name: '04_landing_footer', url: 'http://localhost:5050/', scrollY: 3400, wait: 1500 },
      { name: '05_login', url: 'http://localhost:5050/#/login', scrollY: 0, wait: 2500 },
      { name: '06_register', url: 'http://localhost:5050/#/register', scrollY: 0, wait: 2500 },
      { name: '07_dispatcher_map', url: 'http://localhost:5050/#/dashboard', scrollY: 0, wait: 3500 },
      { name: '08_admin_login', url: 'http://localhost:5050/#/admin/login', scrollY: 0, wait: 2500 },
      { name: '09_admin_dashboard', url: 'http://localhost:5050/#/admin', scrollY: 0, wait: 2500 },
      { name: '10_admin_users', url: 'http://localhost:5050/#/admin/users', scrollY: 0, wait: 2500 },
      { name: '11_admin_registry', url: 'http://localhost:5050/#/admin/registry', scrollY: 0, wait: 2500 },
      { name: '12_admin_logs', url: 'http://localhost:5050/#/admin/logs', scrollY: 0, wait: 2500 }
    ];

    let lastUrl = '';
    for (const step of captureSequence) {
      if (step.url !== lastUrl) {
        console.log(`Navigating to ${step.url}...`);
        await sendCdp(ws, 'Page.navigate', { url: step.url });
        await sleep(step.wait);
        lastUrl = step.url;
      }

      if (step.scrollY > 0) {
        await sendCdp(ws, 'Runtime.evaluate', {
          expression: `window.scrollTo({ top: ${step.scrollY}, behavior: 'instant' });`
        });
        await sleep(800);
      }

      const shot = await sendCdp(ws, 'Page.captureScreenshot', { format: 'png' });
      const filePath = path.join(OUTPUT_DIR, `${step.name}.png`);
      fs.writeFileSync(filePath, Buffer.from(shot.data, 'base64'));
      console.log(`Saved screenshot: ${step.name}.png (${Math.round(shot.data.length / 1024)} KB)`);
    }

    ws.close();
  } catch (err) {
    console.error('Error during capture:', err);
  } finally {
    chrome.kill();
    console.log('Capture finished.');
  }
}

main();
