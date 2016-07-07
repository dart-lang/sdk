dart_library.library('lib/math/coin_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__coin_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const coin_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  coin_test.main = function() {
    let seed = math.Random.new().nextInt(1 << 16);
    core.print(dart.str`coin_test seed: ${seed}`);
    let rnd = math.Random.new(seed);
    let heads = 0;
    let tails = 0;
    for (let i = 0; i < 10000; i++) {
      if (dart.test(rnd.nextBool())) {
        heads++;
      } else {
        tails++;
      }
    }
    core.print(dart.str`Heads: ${heads}\n` + dart.str`Tails: ${tails}\n` + dart.str`Ratio: ${heads / tails}\n`);
    expect$.Expect.approxEquals(1.0, heads / tails, 0.1);
    heads = 0;
    tails = 0;
    for (let i = 0; i < 10000; i++) {
      rnd = math.Random.new(i);
      if (dart.test(rnd.nextBool())) {
        heads++;
      } else {
        tails++;
      }
    }
    core.print(dart.str`Heads: ${heads}\n` + dart.str`Tails: ${tails}\n` + dart.str`Ratio: ${heads / tails}\n`);
    expect$.Expect.approxEquals(1.0, heads / tails, 0.1);
    heads = 0;
    tails = 0;
    for (let i = 0; i < 10000; i++) {
      rnd = math.Random.new();
      if (dart.test(rnd.nextBool())) {
        heads++;
      } else {
        tails++;
      }
    }
    core.print(dart.str`Heads: ${heads}\n` + dart.str`Tails: ${tails}\n` + dart.str`Ratio: ${heads / tails}\n`);
    expect$.Expect.approxEquals(1.0, heads / tails, 0.1);
  };
  dart.fn(coin_test.main, VoidTodynamic());
  // Exports:
  exports.coin_test = coin_test;
});
