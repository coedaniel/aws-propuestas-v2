/** @type {import('next').NextConfig} */
const nextConfig = {
  // Critical for Amplify deployment with App Router
  output: 'export',
  trailingSlash: true,
  images: {
    unoptimized: true
  },
  // Disable server-side features for static export
  experimental: {
    serverComponentsExternalPackages: ['canvas']
  },
  // Environment variables
  env: {
    AWS_REGION: process.env.AWS_REGION || 'us-east-1',
  },
  webpack: (config, { isServer }) => {
    if (isServer) {
      config.externals.push({
        'utf-8-validate': 'commonjs utf-8-validate',
        'bufferutil': 'commonjs bufferutil',
        'canvas': 'commonjs canvas'
      });
    }
    return config;
  }
};

module.exports = nextConfig;
