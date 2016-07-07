dart_library.library('lib/math/low_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__low_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const low_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  low_test.main = function() {
    let n = (2 * (1)[dartx['<<']](32) / 3)[dartx.truncate]();
    let n2 = (n / 2)[dartx.truncate]();
    let iterations = 200000;
    let seed = math.Random.new().nextInt(1 << 16);
    core.print(dart.str`low_test seed: ${seed}`);
    let prng = math.Random.new(seed);
    let low = 0;
    for (let i = 0; i < iterations; i++) {
      if (dart.notNull(prng.nextInt(n)) < n2) {
        low++;
      }
    }
    let diff = (low - (iterations / 2)[dartx.truncate]())[dartx.abs]();
    core.print(dart.str`${low}, ${diff}`);
    expect$.Expect.isTrue(dart.notNull(diff) < (iterations / 20)[dartx.truncate]());
  };
  dart.fn(low_test.main, VoidTovoid());
  // Exports:
  exports.low_test = low_test;
});
