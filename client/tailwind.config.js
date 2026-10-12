/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js}'],
  theme: {
    extend: {
      colors: {
        base: '#0d1117',
        card: '#161b22',
        cardhover: '#1c2530',
        border: '#30363d',
        accent: '#7c6cf0',
        accenthover: '#6a5be0',
        muted: '#8b949e',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      boxShadow: {
        pop: '0 8px 32px rgba(0,0,0,0.45)',
      },
    },
  },
  plugins: [],
}
