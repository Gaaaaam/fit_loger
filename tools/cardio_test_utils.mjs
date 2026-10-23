import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';
import { DatabaseSync } from 'node:sqlite';

export function load(relative, names, dependencies = {}) {
  const source = readFileSync(new URL(`../entry/src/main/ets/${relative}`, import.meta.url), 'utf8')
    .replace(/^import[\s\S]*?from\s+['"][^'"]+['"];\r?\n/gm, '')
    .replace(/@Observed\s*/g, '').replace(/\bexport /g, '');
  const context = { ...dependencies };
  runInNewContext(stripTypeScriptTypes(source) + `\nglobalThis.result = { ${names.join(',')} };`, context);
  return context.result;
}

export function sqliteStore() {
  const db = new DatabaseSync(':memory:');
  class ResultSet {
    constructor(rows) { this.rows = rows; this.index = -1; this.columns = Object.keys(rows[0] ?? {}); }
    goToFirstRow() { this.index = 0; return this.rows.length > 0; }
    goToNextRow() { return ++this.index < this.rows.length; }
    getColumnIndex(key) { return this.columns.indexOf(key); }
    isColumnNull(index) { return this.rows[this.index][this.columns[index]] == null; }
    getString(index) { return String(this.rows[this.index][this.columns[index]]); }
    getLong(index) { return Number(this.rows[this.index][this.columns[index]]); }
    getDouble(index) { return this.getLong(index); }
    close() {}
  }
  class Predicates {
    constructor(table) { this.table = table; this.conditions = []; }
    equalTo(key, value) { this.conditions.push([key, value]); return this; }
  }
  const where = p => p.conditions.map(([key]) => `${key} = ?`).join(' AND ');
  const args = p => p.conditions.map(([, value]) => value);
  const store = {
    version: 0, transactionCount: 0,
    querySql: async (sql, params = []) => new ResultSet(db.prepare(sql).all(...params)),
    executeSql: async (sql, params = []) => db.prepare(sql).run(...params),
    beginTransaction() { this.transactionCount++; db.exec('BEGIN'); },
    commit: () => db.exec('COMMIT'), rollBack: () => db.exec('ROLLBACK'),
    update: async (values, p) => {
      const keys = Object.keys(values);
      db.prepare(`UPDATE ${p.table} SET ${keys.map(key => `${key} = ?`).join(',')} WHERE ${where(p)}`)
        .run(...keys.map(key => values[key]), ...args(p));
    },
    delete: async p => db.prepare(`DELETE FROM ${p.table} WHERE ${where(p)}`).run(...args(p)),
    insert: async (table, values) => {
      const keys = Object.keys(values);
      return Number(db.prepare(`INSERT INTO ${table} (${keys.join(',')}) VALUES (${keys.map(() => '?').join(',')})`)
        .run(...keys.map(key => values[key])).lastInsertRowid);
    }
  };
  return { db, store, relationalStore: { RdbPredicates: Predicates } };
}
