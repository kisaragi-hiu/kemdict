let cjkFallback = [
  "Noto Sans CJK TC",
  "Microsoft Jhenghei",
  "Microsoft Yahei",
  "Meiryo",
  "Malgun Gothic",
];

module.exports = {
  // darkMode: "class",
  content: ["./src/**/*.{njk,html,hbs}"],
  theme: {
    fontFamily: {
      sans: [
        "'Source Sans 3'",
        "'Source Sans Pro'",
        "'Noto Sans CJK TC'",
        "'Noto Sans TC'",
        ...cjkFallback,
        "sans-serif",
      ],
      serif: [
        "'Source Serif Pro'",
        "'Noto Serif CJK TC'",
        "'Noto Serif TC'",
        ...cjkFallback,
        "sans-serif",
      ],
      // serif: ["Equity"],
      mono: [
        "Inconsolata",
        "Noto Sans Mono CJK TC",
        ...cjkFallback,
        "monospace",
      ],
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
};
