import type { Config } from "tailwindcss";

const cjkFallbackSans = [
  "'Noto Sans CJK TC'",
  "'Noto Sans TC'",
  "'jf-openhuninn'",
  "'jf-openhuninn-1.1'",
  "Microsoft Jhenghei",
  "Microsoft Yahei",
  "Meiryo",
  "Malgun Gothic",
];

const cjkFallbackSerif = [
  "'Noto Serif CJK TC'",
  "'Noto Serif TC'",
  "'Iansui 094'",
  "HanaMinA",
  "HanaMinB",
  "花園明朝A",
  "花園明朝B",
  "'Droid Serif'",
];

export default {
  darkMode: "class",
  content: ["./src/**/*.{svelte,md,ts,js,html,astro,mdx}"],
  safelist: ["visible", "invisible"],
  theme: {
    fontFamily: {
      sans: [
        "'Jost*'",
        "'Jost'",
        "Noto Sans",
        ...cjkFallbackSans,
        ...cjkFallbackSerif,
        "sans-serif",
      ],
      serif: [
        "Noto Serif",
        ...cjkFallbackSerif,
        ...cjkFallbackSans,
        "sans-serif",
      ],
      mono: ["monospace"],
    },
    extend: {
      // https://github.com/tailwindlabs/tailwindcss/discussions/1361
      boxShadow: {
        DEFAULT: "0 0 0.25rem #00000040",
        md: "0 0 0.25rem #00000070",
        white: "0 0 0.5rem #ffffff",
      },
    },
  },
  plugins: [require("daisyui")],
  daisyui: {
    prefix: "daisy-",
  },
} satisfies Config;
