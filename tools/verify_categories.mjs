import { strict as assert } from 'node:assert';
import { readFileSync, existsSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';
import { DatabaseSync } from 'node:sqlite';

function load(relative, names, dependencies = {}) {
  const source = readFileSync(new URL(`../entry/src/main/ets/${relative}`, import.meta.url), 'utf8')
    .replace(/^import .*;\r?\n/gm, '').replace(/\bexport /g, '');
  const context = { ...dependencies };
  runInNewContext(stripTypeScriptTypes(source) + `\nglobalThis.result = { ${names.join(',')} };`, context);
  return context.result;
}
const types = load('model/types.ets', ['BODY_PARTS', 'toPartKey', 'partName', 'toEquipment'], { $r: (name) => name });
assert.equal(types.toEquipment('band'), 'band');
assert.equal(types.toEquipment('unknown-kit'), 'other');
const { EXERCISE_CATALOG } = load('model/exerciseCatalog.ets', ['EXERCISE_CATALOG']);
assert.equal(types.BODY_PARTS.length, 9);
for (const part of types.BODY_PARTS) {
  assert.equal(types.toPartKey(part.key), part.key, 'persisted category must survive loading');
  assert.equal(types.partName(part.key), part.name);
  assert(EXERCISE_CATALOG.some((item) => item.partKey === part.key));
  const resource = part.image.replace('app.media.', '');
  assert(existsSync(new URL(`../entry/src/main/resources/base/media/${resource}.svg`, import.meta.url)));
}
const { SQL_CREATE_EXERCISES } = load('db/schemaSql.ets', ['SQL_CREATE_EXERCISES']);
const { seedBuiltinExercises } = load('db/ExerciseSeed.ets', ['seedBuiltinExercises'], { EXERCISE_CATALOG });
const db = new DatabaseSync(':memory:');
db.exec(SQL_CREATE_EXERCISES);
const store = { executeSql: async (sql, args) => db.prepare(sql).run(...args) };
await seedBuiltinExercises(store);
db.prepare('UPDATE exercises SET name = ? WHERE id = ?').run('用户保留名称', 'chest_bb_bench');
await seedBuiltinExercises(store);
assert.equal(db.prepare('SELECT count(*) AS n FROM exercises').get().n, EXERCISE_CATALOG.length);
assert.equal(db.prepare('SELECT name FROM exercises WHERE id = ?').get('chest_bb_bench').name, '用户保留名称');
for (const part of ['abs', 'core', 'cardio']) {
  assert(db.prepare('SELECT count(*) AS n FROM exercises WHERE part_key = ?').get(part).n > 0);
}
db.close();
console.log('Nine category round trips, image resources, and idempotent SQLite seeding passed.');
