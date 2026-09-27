const { launch, open, tap, texts, shot } = require('./lib');
(async () => {
  const { browser, page, errors } = await launch();
  await open(page);
  await page.waitForTimeout(3000);
  console.log(await texts(page));
  await shot(page, '/tmp/smoke1.png');
  await tap(page, 'Next'); await tap(page, 'Next');
  await tap(page, 'Start learning');
  await page.waitForTimeout(1500);
  console.log(await texts(page));
  await shot(page, '/tmp/smoke2.png');
  console.log('errors', errors);
  await browser.close();
})().catch((e) => { console.error(e); process.exit(1); });
