import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['test/**/*.test.js'],
    testTimeout: 20000,
    hookTimeout: 30000,
    // One shared emulator: run files serially so clear/seed calls don't race.
    fileParallelism: false,
    reporters: ['default', 'json'],
    outputFile: { json: './results/vitest.json' },
  },
});
