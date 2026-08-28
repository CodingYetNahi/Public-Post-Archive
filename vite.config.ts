import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  base: '/Public-Post-Archive/',
  plugins: [react()],
})
