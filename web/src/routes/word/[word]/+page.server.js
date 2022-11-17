export const prerender = false;

import { error } from "@sveltejs/kit";
import * as fs from "node:fs";
import * as zlib from "node:zlib";
import Database from "better-sqlite3";
// Do this dance in order to not retain a reference to rawdb.
let db;
{
  let raw;
  // Seems like the path copying doesn't work well with the project
  // being at a subdirectory, so during build we get src/... but
  // during serverless function runtime we get web/src/...
  //
  // TODO: write this down in an article
  try {
    raw = fs.readFileSync("./src/lib/entries.db.gz");
  } catch (e) {
    if (e instanceof Error && e.code === "ENOENT") {
      raw = fs.readFileSync("./web/src/lib/entries.db.gz");
    } else {
      throw e;
    }
  }
  let rawdb = zlib.gunzipSync(raw);
  db = new Database(rawdb);
}

const statement_word = db.prepare("select * from entries where title = ?");
/**
 * Return the word object from the DB.
 * @param {string} title
 * @returns {object}
 */
function getWord(title) {
  // If the word doesn't exist it'll simply return `undefined`.
  let ret = statement_word.get(title);
  if (ret) {
    for (let prop in ret) {
      if (prop !== "title") {
        ret[prop] = JSON.parse(ret[prop]);
      }
    }
  }
  return ret;
}

/** @type {import('./$types').PageServerLoad} */
export function load({ params }) {
  // This uses /word/<word>.
  //
  // If we want /word/?word=<word>:
  //
  // - make this function receive `url` instead
  // - put this file and +page.svelte in word/ instead of word/[word]/
  // - read url.searchParams.get("word") instead of params.word
  //
  // And remember to update links pointing here elsewhere.
  const w = params.word;
  const word = getWord(w);

  if (word) {
    return { word: word };
  } else {
    throw error(404, "`Word ${w} not found.`");
  }
}
