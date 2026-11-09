// Render the A3 SVG sheets in a folder to one PDF with headless Chromium (Playwright).
// usage: node tools/render_pdf.js <svg-folder> <output.pdf> [png-preview-folder]
const { chromium } = require('playwright');
const fs = require('fs'); const path = require('path');
(async () => {
  const [dir, out, pngDir] = process.argv.slice(2);
  const files = fs.readdirSync(dir).filter(f => /^PGB-ENC-001_sheet\d+\.svg$/.test(f)).sort();
  const svgs = files.map(f => fs.readFileSync(path.join(dir, f), 'utf8'));
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1587, height: 1123 } });
  if (pngDir) for (let i = 0; i < svgs.length; i++) {
    await p.setContent(`<body style="margin:0">${svgs[i].replace("width='420mm' height='297mm'", "width='1587' height='1123'")}</body>`);
    await p.screenshot({ path: path.join(pngDir, `sheet${i + 1}.png`) });
  }
  await p.setContent(`<html><head><style>@page{size:420mm 297mm;margin:0}body{margin:0}svg{display:block;page-break-after:always}</style></head><body>${svgs.join('')}</body></html>`);
  await p.pdf({ path: out, width: '420mm', height: '297mm', printBackground: true });
  await b.close();
})();
