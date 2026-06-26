import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        navy: {
          DEFAULT: '#0A1A3A',
          light:   '#0F2756',
          card:    '#0D2145',
          hover:   '#132D63',
          border:  'rgba(255,255,255,0.08)',
        },
        gold: {
          DEFAULT: '#D4AF37',
          light:   '#E8D080',
          dark:    '#A88A28',
          dim:     'rgba(212,175,55,0.15)',
        },
      },
      fontFamily: {
        sans: ['var(--font-inter)', 'sans-serif'],
        mono: ['var(--font-mono)', 'ui-monospace', 'monospace'],
      },
    },
  },
  plugins: [require('@tailwindcss/forms')],
}

export default config
