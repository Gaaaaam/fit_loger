// Re-encode generated originals; no image synthesis or retouching is performed here.
const sharp = require('sharp');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const manifest = require('./body_parts_v2.json');

async function main() {
  for (const asset of manifest.assets) {
    const source = await sharp(asset.source).metadata();
    if (!source.hasAlpha) throw new Error(`${asset.key}: generated source must have alpha`);
    const output = path.join(root, 'entry/src/main/resources/base/media', `part_${asset.key}_v2.webp`);
    await sharp(asset.source)
      .resize(608, 448, { fit: 'contain', background: '#00000000' })
      .extend({ top: 16, bottom: 16, left: 16, right: 16, background: '#00000000' })
      .webp({ quality: manifest.output.quality, alphaQuality: 100, effort: 6 })
      .toFile(output);
    const { data, info } = await sharp(output).raw().toBuffer({ resolveWithObject: true });
    let visible = 0, transparent = 0;
    for (let i = 3; i < data.length; i += info.channels) {
      if (data[i] > 0) visible++;
      if (data[i] === 0) transparent++;
    }
    if (info.width !== 640 || info.height !== 480 || info.channels !== 4 || !visible || !transparent) {
      throw new Error(`${asset.key}: invalid dimensions or transparency`);
    }
    console.log(`${asset.key}: 640x480 RGBA, ${fs.statSync(output).size} bytes`);
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
