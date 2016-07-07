dart_library.library('lib/math/random_big_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__random_big_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const random_big_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  random_big_test.main = function() {
    let results = [];
    for (let i = 60; i < 80; i++) {
      let rng = math.Random.new((1)[dartx['<<']](i));
      let val = rng.nextInt(100000);
      core.print(dart.str`${i}: ${val}`);
      expect$.Expect.isFalse(results[dartx.contains](val));
      results[dartx.add](val);
    }
  };
  dart.fn(random_big_test.main, VoidTodynamic());
  // Exports:
  exports.random_big_test = random_big_test;
});
