import { copyFileSync, existsSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const profilePath = join(root, 'build-profile.json5');
const localPath = join(root, 'build-profile.signing.local.json5');

function loadJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

function saveJson(path, value) {
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`);
}

function stripSigning(profile) {
  profile.app.signingConfigs = [];
  for (const product of profile.app.products ?? []) {
    delete product.signingConfig;
  }
  return profile;
}

function applySigning(profile, local) {
  profile.app.signingConfigs = local.signingConfigs;
  const name = local.productSigningConfig;
  if (name) {
    for (const product of profile.app.products ?? []) {
      product.signingConfig = name;
    }
  }
  return profile;
}

function backupThenWrite(path, value) {
  if (existsSync(path)) {
    copyFileSync(path, `${path}.local.bak`);
  }
  saveJson(path, value);
}

const command = process.argv[2] ?? 'help';

if (command === 'strip') {
  const profile = stripSigning(loadJson(profilePath));
  backupThenWrite(profilePath, profile);
  console.log('stripped signingConfigs from build-profile.json5');
} else if (command === 'apply') {
  if (!existsSync(localPath)) {
    throw new Error(`missing ${localPath}; configure signing in DevEco or restore this file first`);
  }
  const profile = applySigning(loadJson(profilePath), loadJson(localPath));
  backupThenWrite(profilePath, profile);
  console.log('applied local signing into build-profile.json5 (do not commit this file)');
} else if (command === 'save') {
  const profile = loadJson(profilePath);
  const configs = profile.app.signingConfigs ?? [];
  if (!Array.isArray(configs) || configs.length === 0) {
    throw new Error('build-profile.json5 has no signingConfigs to save');
  }
  saveJson(localPath, {
    productSigningConfig: profile.app.products?.[0]?.signingConfig ?? 'default',
    signingConfigs: configs
  });
  console.log(`saved local signing to ${localPath}`);
} else {
  console.log(`usage:
  node tools/local_signing.mjs save   # copy signing out of build-profile.json5
  node tools/local_signing.mjs strip  # empty signingConfigs for git
  node tools/local_signing.mjs apply  # restore gitignored signing for DevEco`);
  process.exit(command === 'help' ? 0 : 1);
}
