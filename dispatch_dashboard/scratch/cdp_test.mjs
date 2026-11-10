import { spawn } from 'child_process';
import http from 'http';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9222;

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

async function main() {
  console.log('Spawning Chrome headless...');
  const chrome = spawn(CHROME_PATH, [
    '--headless=new',
    `--remote-debugging-port=${PORT}`,
    '--disable-gpu',
    '--no-first-run',
    '--user-data-dir=C:\\Users\\Ruhama\\.gemini\\antigravity\\brain\\32f56c3d-e968-4b59-96e7-cd73ebe9f589\\scratch\\chrome_user_data',
    'http://localhost:5050/'
  ]);

  await sleep(2500);

  try {
    const version = await fetchJson(`http://127.0.0.1:${PORT}/json/version`);
    console.log('Connected to Chrome:', version.Browser);
    const pages = await fetchJson(`http://127.0.0.1:${PORT}/json/list`);
    console.log('Available pages:', pages.length, pages[0]?.url);
  } catch (err) {
    console.error('Error connecting to Chrome:', err);
  } finally {
    chrome.kill();
    console.log('Chrome closed.');
  }
}

main();
