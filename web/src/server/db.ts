import { chunk, sortBy, uniqBy } from "lodash-es";
import { groupByProp, parseQuery, CrossDB } from "common";
import { spc } from "$lib/processing";
import type { Heteronym, LangId, Mtch } from "common";

import { lPush } from "$src/localStorage";

export async function readDB() {
  const fs = await import("node:fs");
  const Database = (await import("better-sqlite3")).default;
  const path = [
    "../kemdict.db",
    "./entries.db",
    "../dicts/entries.db",
    "../../dicts/entries.db",
  ].find((f) => fs.existsSync(f));
  if (!path) throw new Error("DB not found!");
  const db = new Database(path, {
    readonly: true,
    fileMustExist: true,
  });
  return db;
}

export const DB = new CrossDB("web", readDB);

export const chars = await (async () => {
  const { with_stroke, without_stroke } = await DB.getChars();
  const with_stroke_grouped = chunk(sortBy(with_stroke, "sc"), 1200).map(
    (page) => groupByProp(page, "sc")
  );
  return { without_stroke, with_stroke_grouped };
})();

/** Return the preview text of `het`. */
export function hetPreview(het: Heteronym) {
  function strip(html: string | undefined): string {
    // https://stackoverflow.com/a/822464/6927814
    // This doesn't have to be perfect. We're not handling untrusted
    // input either.
    return html?.replace(/<[^>]*>?/gm, "") || "";
  }
  return strip(
    het.props.def ||
      het.props.defs?.map((x) => x.def).join("") ||
      het.props.example ||
      het.props.zh
  );
}

/**
 * Return true if `het` can be an exact match and `query` matches it
 * exactly.
 */
export function hetExactMatch(het: Heteronym, query: string | undefined) {
  return !!(het.exact && query && het.title === query);
}

// TODO: rename
export function processPn(het: Heteronym) {
  // FIXME: for Hakkadict, it's questionable for me to pick one
  // dialect out of the six provided.
  const pron_keys = [
    "bopomofo",
    "trs",
    "pronunciation",
    "p_四縣",
    "kip",
    "poj",
  ];
  let pn: string | undefined =
    het.props[pron_keys.find((pron) => het.props[pron])];
  if (pn && het.title !== pn) {
    return `（${spc(pn)}）`;
  } else {
    return "";
  }
}

/**
 * Like search/index.astro's load() function.
 */
export async function getHetFromUrl(
  url: URL,
  lang?: string
): Promise<
  [
    boolean,
    (
      | {
          heteronyms: Heteronym[];
          mtch: string;
          query: string;
          originalQuery: string;
          langSet: Set<LangId>;
          langCountObj: Record<LangId, number>;
        }
      | string
    ) // when the first item is false, this is a string
  ]
> {
  /** Query text as written in the URL */
  const originalQuery: string | undefined = url.searchParams.get("q")?.trim();
  /** Unicode normalized query */
  const query = originalQuery?.normalize("NFC");
  const mtch: Mtch = url.searchParams.get("m") || "prefix";
  const sort: string = url.searchParams.get("s") || "desc";
  /**
   * When this flag is provided, if there is only one match, we
   * redirect to it.
   */
  const redirectOnSingleResult = url.searchParams.has("r");
  // Invalid: redirect to root
  if (typeof query !== "string" || query.length === 0) {
    return [false, "/"];
  }
  const parsed = parseQuery(query);
  const { presentLangSet, heteronyms, langCountObj } = await DB.getHeteronyms(
    parsed,
    {
      mtch,
      langs: lang,
    }
  );
  // Redirect if all matched heteronyms belong to the same title
  if (
    redirectOnSingleResult &&
    mtch === "prefix" &&
    heteronyms &&
    // The query is just text, no filters and no exclusions
    Object.keys(parsed).length === 1 &&
    // The query does not invoke the "second token uses contains
    // matching" logic
    !query.match(/\s/) &&
    heteronyms.length > 0 &&
    heteronyms.length < 10 &&
    heteronyms.every((x) => x.title === heteronyms[0].title)
  ) {
    return [
      false,
      encodeURI(
        heteronyms.length === 1
          ? `/word/${heteronyms[0].title}?lang=${heteronyms[0].lang}`
          : `/word/${heteronyms[0].title}`
      ),
    ];
  }
  if (sort === "desc") {
    // Negative -> a comes first
    // Positive -> b comes first
    // 0 -> keep
    heteronyms.sort((a: Heteronym, b: Heteronym) => {
      if (a.exact && a.title === query) return -1;
      if (b.exact && b.title === query) return 1;
      return a.title < b.title ? -1 : 1;
    });
  } else {
    heteronyms.sort((a: Heteronym, b: Heteronym) => {
      if (a.exact && a.title === query) return -1;
      if (b.exact && b.title === query) return 1;
      return a.title > b.title ? -1 : 1;
    });
  }
  return [
    true,
    {
      heteronyms: uniqBy(heteronyms, (het) => {
        return (
          het.title +
          het.lang +
          het.from +
          processPn(het) +
          `${hetExactMatch(het, query)}`
        );
      }),
      mtch,
      query,
      originalQuery,
      langSet: presentLangSet,
      langCountObj,
    },
  ];
}

/**
 * Append the POJ version of a heteronym to the title if applicable.
 */
export function taigiTitle(het: Heteronym): string {
  // title is set to kip in the dicts Makefile;
  // Show POJ in title if they're not equal.
  if (het.props.titlePoj && het.title !== het.props.titlePoj) {
    return `${het.title} (${het.props.titlePoj})`;
  } else {
    return het.title;
  }
}
