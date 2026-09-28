// Shared helpers for driving the Flutter web build with Playwright (semantics enabled via WEB_TEST).
const { chromium } = require('/opt/node22/lib/node_modules/playwright');

async function launch({ width = 390, height = 844 } = {}) {
  // Fonts come from Google Fonts through the HTTPS proxy; the app itself is served on loopback.
  const args = ['--ignore-certificate-errors'];
  if (process.env.HTTPS_PROXY) args.push(`--proxy-server=${process.env.HTTPS_PROXY}`, '--proxy-bypass-list=127.0.0.1;localhost');
  const browser = await chromium.launch({ args });
  const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 2, locale: 'en-GB' });
  const errors = [];
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', (e) => errors.push(String(e)));
  return { browser, page, errors };
}

async function open(page, url = 'http://127.0.0.1:8080/', { fresh = true } = {}) {
  await page.goto(url);
  if (fresh) {
    await page.evaluate(() => localStorage.clear());
    await page.goto(url);
  }
  await page.waitForSelector('flt-semantics', { timeout: 30000, state: 'attached' });
  await page.waitForTimeout(800);
}

// Finds a semantics node whose accessible text contains `text` and clicks its centre.
async function tap(page, text, { exact = false, nth = 0, timeout = 8000 } = {}) {
  const deadline = Date.now() + timeout;
  while (true) {
    const box = await page.evaluate(({ text, exact, nth }) => {
      const nodes = [...document.querySelectorAll('flt-semantics')];
      const label = (n) => ((n.getAttribute('aria-label') || '') + ' ' + (n.innerText || '')).replace(/\s+/g, ' ').trim();
      const hits = nodes.filter((n) => {
        const l = label(n);
        return exact ? (n.getAttribute('aria-label') || n.innerText || '').trim() === text : l.includes(text);
      });
      // Prefer the deepest match (leaf-most node).
      const leaf = hits.filter((n) => !hits.some((o) => o !== n && n.contains(o)));
      const n = leaf[nth];
      if (!n) return null;
      const r = n.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) return null;
      return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
    }, { text, exact, nth });
    if (box) { await page.mouse.click(box.x, box.y); await page.waitForTimeout(450); return true; }
    if (Date.now() > deadline) throw new Error(`tap: "${text}" not found`);
    await page.waitForTimeout(250);
  }
}

async function has(page, text) {
  return page.evaluate((text) => [...document.querySelectorAll('flt-semantics')].some((n) =>
    ((n.getAttribute('aria-label') || '') + ' ' + (n.innerText || '')).includes(text)), text);
}

async function texts(page) {
  return page.evaluate(() => [...new Set([...document.querySelectorAll('flt-semantics')].map((n) => (n.getAttribute('aria-label') || '').trim()).filter(Boolean))]);
}

async function shot(page, path) { await page.waitForTimeout(500); await page.screenshot({ path }); }

async function scroll(page, dy = 500, x = 195, y = 450) { await page.mouse.move(x, y); await page.mouse.wheel(0, dy); await page.waitForTimeout(500); }

async function type(page, s) { await page.keyboard.type(s, { delay: 30 }); await page.waitForTimeout(300); }

module.exports = { launch, open, tap, has, texts, shot, scroll, type };
