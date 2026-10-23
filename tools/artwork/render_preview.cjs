const sharp = require('sharp');
const fs = require('node:fs');
const path = require('node:path');
const { stripTypeScriptTypes } = require('node:module');
const { runInNewContext } = require('node:vm');
const root = path.resolve(__dirname, '../..');
const source = fs.readFileSync(path.join(root, 'entry/src/main/ets/model/types.ets'), 'utf8').replace(/^export /gm, '');
const context = { $r: name => name.replace('app.media.', '') };
runInNewContext(stripTypeScriptTypes(source) + '\nglobalThis.parts = BODY_PARTS;', context);
const parts = context.parts;
const themes = ['light', 'dark'].map(name => {
  const folder = name === 'dark' ? 'dark' : 'base';
  const { color } = JSON.parse(fs.readFileSync(path.join(root, `entry/src/main/resources/${folder}/element/color.json`), 'utf8'));
  return { name, colors: Object.fromEntries(color.map(item => [item.name, item.value])) };
});
const escape = value => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

async function render(compact, theme) {
  const { colors: c } = theme;
  const cw = compact ? 168 : 320, ch = compact ? 180 : 286;
  const cols = compact ? 2 : 3, gap = 12, margin = 16, header = 60;
  const imageHeight = compact ? 100 : 206;
  const width = cols * cw + (cols - 1) * gap + margin * 2;
  const height = header + Math.ceil(parts.length / cols) * (ch + gap) - gap + 24;
  const layers = [];
  const background = `<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="${c.page_bg}"/><text x="16" y="33" font-family="Microsoft YaHei" font-size="20" font-weight="500" fill="${c.text_primary}">选择训练部位 / 类型</text></svg>`;
  for (const [index, part] of parts.entries()) {
    const x = margin + (index % cols) * (cw + gap);
    const y = header + Math.floor(index / cols) * (ch + gap);
    const labelY = imageHeight + 36;
    const charsPerLine = Math.floor((cw - 24) / 12);
    const lines = [];
    for (let i = 0; i < part.description.length; i += charsPerLine) lines.push(part.description.slice(i, i + charsPerLine));
    const description = lines.slice(0, 2).map((line, i) => `<text x="${cw / 2}" y="${labelY + 22 + i * 14}" text-anchor="middle" font-family="Microsoft YaHei" font-size="12" fill="${c.text_secondary}">${escape(line)}</text>`).join('');
    const card = `<svg width="${cw}" height="${ch}" xmlns="http://www.w3.org/2000/svg"><rect x=".5" y=".5" width="${cw - 1}" height="${ch - 1}" rx="16" fill="${c.card_bg}" stroke="${c.divider}"/><text x="${cw / 2}" y="${labelY}" text-anchor="middle" font-family="Microsoft YaHei" font-size="18" font-weight="500" fill="${c.text_primary}">${escape(part.name)}</text>${description}</svg>`;
    layers.push({ input: Buffer.from(card), left: x, top: y });
    const image = await sharp(path.join(root, `entry/src/main/resources/base/media/${part.image}.webp`)).resize(cw - 24, imageHeight, { fit: 'contain', background: '#00000000' }).png().toBuffer();
    layers.push({ input: image, left: x + 12, top: y + 12 });
  }
  const filename = `preview-v2${compact ? '-compact' : ''}${theme.name === 'dark' ? '-dark' : ''}.png`;
  const output = path.join(__dirname, filename);
  await sharp(Buffer.from(background)).composite(layers).png().toFile(output);
  return { output, width, height };
}

function renderHtml() {
  const articles = parts.map(part => `<article><img src="../../entry/src/main/resources/base/media/${part.image}.webp" alt="${escape(part.name)}训练部位示意"><h2>${escape(part.name)}</h2><p>${escape(part.description)}</p></article>`).join('\n');
  const palette = theme => Object.entries(theme.colors).map(([key, value]) => `--${key}:${value}`).join(';');
  const html = `<!DOCTYPE html>
<html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>训练部位分类图片预览</title>
<style>
:root{${palette(themes[0])}}body.dark{${palette(themes[1])}}
*{box-sizing:border-box}body{margin:0;padding:16px;background:var(--page_bg);color:var(--text_primary);font-family:"Microsoft YaHei",sans-serif}
header,main{max-width:1000px;margin:auto}header{display:flex;align-items:center;justify-content:space-between;margin-bottom:20px}h1{font-size:20px;font-weight:500;margin:0}
button{background:var(--card_bg);color:var(--text_primary);border:1px solid var(--divider);border-radius:8px;padding:6px 10px;cursor:pointer}
main{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}article{height:286px;padding:12px;border:1px solid var(--divider);border-radius:16px;background:var(--card_bg);text-align:center;overflow:hidden}img{display:block;width:100%;height:206px;object-fit:contain}h2{margin:6px 0;font-size:18px;line-height:22px;font-weight:500}p{margin:0;font-size:12px;line-height:14px;color:var(--text_secondary)}
body.compact header,body.compact main{max-width:348px}body.compact main{grid-template-columns:repeat(2,1fr)}body.compact article{height:180px}body.compact img{height:100px}
@media(max-width:600px){header,main{max-width:348px}main{grid-template-columns:repeat(2,1fr)}article{height:180px}img{height:100px}}
</style>
<header><h1>选择训练部位 / 类型</h1><button type="button" id="theme-toggle" aria-label="切换浅色或暗色预览">切换主题</button></header>
<main>${articles}</main>
<script>const params=new URLSearchParams(location.search);document.body.classList.toggle('compact',params.get('mode')==='compact');document.body.classList.toggle('dark',params.get('theme')==='dark'||params.get('mode')==='dark');document.getElementById('theme-toggle').onclick=()=>document.body.classList.toggle('dark');</script></html>`;
  fs.writeFileSync(path.join(__dirname, 'preview-v2.html'), html, 'utf8');
}

async function main() {
  const compact = [];
  for (const theme of themes) {
    await render(false, theme);
    compact.push(await render(true, theme));
  }
  await sharp({ create: { width: compact[0].width * 2 + 16, height: compact[0].height, channels: 4, background: '#6B7280' } }).composite(compact.map((item, index) => ({ input: item.output, left: index * (item.width + 16), top: 0 }))).png().toFile(path.join(__dirname, 'preview-v2-themes.png'));
  renderHtml();
  console.log('Rendered all nine picker resources in light/dark themes, including 100px image previews.');
}

main().catch(error => { console.error(error); process.exitCode = 1; });
