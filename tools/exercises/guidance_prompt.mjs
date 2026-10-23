import { readFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
import { parseArgs } from 'node:util';

const defaultManifest = fileURLToPath(new URL('./guidance.json', import.meta.url));
const catalog = JSON.parse(readFileSync(new URL('./curated.json', import.meta.url), 'utf8')).exercises;
const layoutCounts = { 'horizontal-2': 2, 'horizontal-3': 3, 'grid-4': 4 };
export const GUIDANCE_AVOID = 'no text, no watermark, no labels, no numbers, no logos, no arrows, ' +
  'no decorative borders, no panel gutters, no cropped body or equipment, no extra or missing limbs or fingers, ' +
  'no distorted anatomy, no floating equipment, no inconsistent grips or contact points, ' +
  'no exaggerated muscles, no sexualized poses, no busy background';

export function loadGuidanceManifest(path = defaultManifest) {
  const data = JSON.parse(readFileSync(path, 'utf8'));
  if (!data || !Array.isArray(data.exercises)) throw new Error('manifest must contain an exercises array');
  const seen = new Set();
  for (const entry of data.exercises) {
    if (!entry || typeof entry.id !== 'string' || !/^[a-z][a-z0-9_]*$/.test(entry.id)) {
      throw new Error('invalid exercise ID');
    }
    if (seen.has(entry.id)) throw new Error(`duplicate ID: ${entry.id}`);
    seen.add(entry.id);
    if (typeof entry.layout !== 'string' || !Object.hasOwn(layoutCounts, entry.layout)) {
      throw new Error(`${entry.id}: invalid layout`);
    }
    if (!Number.isInteger(entry.frameCount) || entry.frameCount !== layoutCounts[entry.layout]) {
      throw new Error(`${entry.id}: frameCount does not match layout`);
    }
    if (!Array.isArray(entry.captions) || entry.captions.length !== entry.frameCount ||
        entry.captions.some(caption => typeof caption !== 'string' || !caption.trim())) {
      throw new Error(`${entry.id}: caption-count mismatch or empty caption`);
    }
    if (!Number.isInteger(entry.cardFrameIndex) || entry.cardFrameIndex < 0 || entry.cardFrameIndex >= entry.frameCount) {
      throw new Error(`${entry.id}: cardFrameIndex out of range`);
    }
    if (!['planned', 'approved'].includes(entry.status)) throw new Error(`${entry.id}: invalid status`);
    for (const field of ['partKey', 'view', 'equipmentNotes', 'muscleNotes']) {
      if (typeof entry[field] !== 'string' || !entry[field].trim()) throw new Error(`${entry.id}: missing ${field}`);
    }
    for (const field of ['movementReference', 'secondaryMusclesOverride']) {
      if (entry[field] !== undefined && (typeof entry[field] !== 'string' || !entry[field].trim())) {
        throw new Error(`${entry.id}: invalid ${field}`);
      }
    }
    const exercise = catalog.find(item => item.id === entry.id);
    if (!exercise || exercise.partKey !== entry.partKey) throw new Error(`${entry.id}: catalog ID/partKey mismatch`);
  }
  return data.exercises;
}

export function buildGuidanceJob(entry, gender) {
  if (!['female', 'male'].includes(gender)) throw new Error(`invalid gender: ${gender}`);
  const exercise = catalog.find(item => item.id === entry.id);
  if (!exercise) throw new Error(`unknown catalog ID: ${entry.id}`);
  const arrangement = entry.layout === 'grid-4'
    ? 'a 2 by 2 grid of equal 768x512 cells, ordered top-left, top-right, bottom-left, bottom-right'
    : `one row of ${entry.frameCount} equal ${1536 / entry.frameCount}x1024 columns, ordered left to right`;
  const movementReference = entry.movementReference ??
    `start ${exercise.startPosition} Steps: ${exercise.steps.join(' ')} Cues: ${exercise.cues.join(' ')}`;
  const secondaryMuscles = entry.secondaryMusclesOverride ?? exercise.secondaryMusclesZh;
  const prompt = [
    `Create a scientific-educational exercise guidance illustration of ${exercise.englishName} (${exercise.name}).`,
    `Output one 1536x1024 mother sheet in ${entry.layout} layout: ${arrangement}.`,
    `Show the same adult ${gender} fitness model in every cell, wearing modest fitted training clothing.`,
    'Keep consistent identity, body proportions, clothing, equipment, camera angle, camera distance and soft lighting across all stages.',
    'Use a plain neutral background and clear realistic anatomical form with restrained muscle overlays.',
    `Use a ${entry.view}. Keep full-body framing in every cell, including head, hands, feet and all equipment, with a safe margin.`,
    'Scale and center the complete person plus all equipment within the central 70 percent of each panel width and height, leaving visible neutral background on every side; no body part or equipment may touch a panel boundary.',
    `Stage semantics, in exact reading order (instructions only, never render captions): ${entry.captions.map((caption, index) => `${index + 1}: ${caption}`).join('; ')}.`,
    `Equipment: ${exercise.equipment}. ${entry.equipmentNotes}`,
    `Target muscles: ${exercise.primaryMusclesZh}; supporting muscles: ${secondaryMuscles}. ${entry.muscleNotes}`,
    'Render each target muscle as a flat translucent green overlay conforming to the natural body surface; no raised gray segmented muscles, no added muscle volume or distorted joints. Keep natural athlete proportions in every stage.',
    `Movement reference: ${movementReference}`,
    'The manifest-selected variation is authoritative for setup, grip, stance, handle and stage order; catalog alternatives must not appear as extra variants or frames.',
    'Illustrate the specified stages only; catalog return phases or optional variations do not add panels.',
    `Avoid: ${GUIDANCE_AVOID}.`
  ].join('\n');
  return { id: entry.id, gender, sheetPath: `.work/exercise-guidance/${entry.id}/${gender}-sheet.png`, prompt };
}

function main() {
  const { values, positionals } = parseArgs({ options: {
    manifest: { type: 'string', default: defaultManifest },
    check: { type: 'boolean' }, jobs: { type: 'boolean' }, part: { type: 'string' },
    'require-all': { type: 'boolean' }
  }, allowPositionals: true });
  if (values['require-all'] && !values.check) throw new Error('--require-all requires --check');
  const entries = loadGuidanceManifest(values.manifest);
  if (values.check) {
    if (values.jobs || positionals.length || (values.part && values['require-all'])) {
      throw new Error('--check cannot be combined with job selection or --require-all --part');
    }
    if (values['require-all']) {
      const manifestIds = new Set(entries.map(entry => entry.id));
      const catalogIds = new Set(catalog.map(item => item.id));
      const missing = [...catalogIds].filter(id => !manifestIds.has(id));
      const extra = [...manifestIds].filter(id => !catalogIds.has(id));
      if (missing.length || extra.length) {
        throw new Error(`catalog coverage mismatch: missing (${missing.length}): ${missing.join(', ')}; extra (${extra.length}): ${extra.join(', ')}`);
      }
    }
    const checkedEntries = values.part ? entries.filter(entry => entry.partKey === values.part) : entries;
    if (!checkedEntries.length) throw new Error(`no guidance entries for part: ${values.part}`);
    for (const entry of checkedEntries) {
      for (const gender of ['female', 'male']) {
        const { prompt } = buildGuidanceJob(entry, gender);
        for (const term of ['no text', 'no watermark', gender, entry.layout, ...entry.captions]) {
          if (!prompt.includes(term)) throw new Error(`${entry.id}/${gender}: missing ${term}`);
        }
      }
    }
    console.log(`PASS: entries=${checkedEntries.length}, prompts=${checkedEntries.length * 2}, approved=${checkedEntries.filter(entry => entry.status === 'approved').length}, planned=${checkedEntries.filter(entry => entry.status === 'planned').length}`);
  } else if (values.jobs) {
    if (positionals.length) throw new Error('--jobs does not accept exercise/gender arguments');
    for (const entry of entries) {
      if (entry.status !== 'planned' || (values.part && entry.partKey !== values.part)) continue;
      for (const gender of ['female', 'male']) console.log(JSON.stringify(buildGuidanceJob(entry, gender)));
    }
  } else {
    if (positionals.length !== 2 || values.part) throw new Error('usage: guidance_prompt.mjs ID female|male, --check, or --jobs [--part PART]');
    const entry = entries.find(item => item.id === positionals[0]);
    if (!entry) throw new Error(`unknown guidance ID: ${positionals[0]}`);
    console.log(JSON.stringify(buildGuidanceJob(entry, positionals[1])));
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try { main(); } catch (error) { console.error(error.message); process.exitCode = 1; }
}
