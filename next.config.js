/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverComponentsExternalPackages: ['canvas']
  },
  // Fix for Amplify deployment
  trailingSlash: true,
  images: {
    unoptimized: true
  },
  // Ensure proper routing
  async rewrites() {
    return [
      {
        source: '/:path*',
        destination: '/:path*',
      },
    ]
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
  },
  env: {
    AWS_REGION: process.env.AWS_REGION || 'us-east-1',
  }
};

module.exports = nextConfig;
