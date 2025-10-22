/** @type {import('next').NextConfig} */
const nextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
  output: 'standalone',
  experimental: {
    isrMemoryCacheSize: 0,
  },
  env: {
    NEXT_PHASE: process.env.NEXT_PHASE || '',
  },
  generateBuildId: async () => {
    return 'build-' + Date.now()
  },
  webpack: (config) => {
    config.externals.push({
      'mysql2': 'commonjs mysql2'
    })
    return config
  }
}

export default nextConfig
