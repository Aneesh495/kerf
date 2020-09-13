# Test suite execution harness and assertion utilities
# Enforces strict validation without external framework dependencies

assert = require 'assert'

total-tests = 0
passed-tests = 0
failed-tests = 0
suite-stack = []

describe = (name, fn) ->
  suite-stack.push name
  prefix = suite-stack.join " > "
  console.log "\n[SUITE] #prefix"
  try
    fn!
  catch err
    console.error "  Suite error in #prefix: #{err.message}"
    console.error err.stack
    failed-tests := failed-tests + 1
  suite-stack.pop!

test-case = (name, fn) ->
  total-tests := total-tests + 1
  try
    fn!
    passed-tests := passed-tests + 1
    console.log "  ✓ #name"
  catch err
    failed-tests := failed-tests + 1
    console.error "  ✗ #name"
    console.error "    Error: #{err.message}"
    if err.expected? and err.actual?
      console.error "    Expected: #{err.expected}"
      console.error "    Actual:   #{err.actual}"

assert-approx = (actual, expected, eps = 1e-6, msg = '') ->
  diff = Math.abs(actual - expected)
  if diff > eps
    throw new Error "Assertion failed: expected #{expected} approx (+/- #{eps}), got #{actual}. #{msg}"

get-summary = ->
  total: total-tests
  passed: passed-tests
  failed: failed-tests

reset-counts = ->
  total-tests := 0
  passed-tests := 0
  failed-tests := 0

module.exports = {
  describe
  test-case
  test: test-case
  assert
  assert-approx
  get-summary
  reset-counts
}
