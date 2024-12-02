import * as path from 'node:path';
import { defineConfig } from 'rspress/config';

export default defineConfig({
  root: path.join(__dirname, 'static'),
  title: 'Media over QUIC',
  description:
    'Media over QUIC is a new live media protocol standard in development.',
  icon: '/favicon.svg',
  logo: '/logo.svg',
  globalStyles: path.join(__dirname, 'styles/index.css'),
});
