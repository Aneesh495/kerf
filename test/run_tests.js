// Test runner orchestrator for kerf test suites
require('livescript');
const path = require('path');
const fs = require('fs');
const { getSummary } = require('./test_runner_utils');

console.log('======================================================');
console.log('  KERF TEST HARNESS - EXECUTION & VERIFICATION PASS   ');
console.log('======================================================');

const testDir = __dirname;
const testFiles = fs.readdirSync(testDir)
  .filter(file => file.startsWith('test_') && file.endsWith('.ls') && file !== 'test_runner_utils.ls')
  .sort();

if (testFiles.length === 0) {
  console.log('No test files registered yet.');
  process.exit(0);
}

const startTime = Date.now();

for (const file of testFiles) {
  const filePath = path.join(testDir, file);
  try {
    require(filePath);
  } catch (err) {
    console.error(`Fatal crash loading ${file}: ${err.message}`);
    console.error(err.stack);
    process.exit(1);
  }
}

const elapsedMs = Date.now() - startTime;
const summary = getSummary();

console.log('\n======================================================');
console.log(`KERF TEST RESULTS: ${summary.passed}/${summary.total} passed (${summary.failed} failed) in ${elapsedMs}ms`);
console.log('======================================================');

if (summary.failed > 0) {
  console.error('\nFAILURES DETECTED. Review logs above.');
  process.exit(1);
} else {
  console.log('\nALL TEST SUITES PASSED SUCCESSFULLY.');
  process.exit(0);
}
