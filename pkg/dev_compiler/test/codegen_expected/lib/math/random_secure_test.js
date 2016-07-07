dart_library.library('lib/math/random_secure_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__random_secure_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const random_secure_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  random_secure_test.main = function() {
    let results = null;
    let rng0 = null;
    let rng1 = null;
    let checkInt = dart.fn(max => {
      let intVal0 = dart.dsend(rng0, 'nextInt', max);
      let intVal1 = dart.dsend(rng1, 'nextInt', max);
      if (dart.test(dart.dsend(max, '>', 1 << 28))) {
        expect$.Expect.isFalse(dart.dsend(results, 'contains', intVal0));
        dart.dsend(results, 'add', intVal0);
        expect$.Expect.isFalse(dart.dsend(results, 'contains', intVal1));
        dart.dsend(results, 'add', intVal1);
      }
    }, dynamicTodynamic());
    results = [];
    rng0 = math.Random.secure();
    for (let i = 0; i <= 32; i++) {
      rng1 = math.Random.secure();
      dart.dcall(checkInt, math.pow(2, 32));
      dart.dcall(checkInt, math.pow(2, 32 - i));
      dart.dcall(checkInt, 1000000000);
    }
    let checkDouble = dart.fn(() => {
      let doubleVal0 = dart.dsend(rng0, 'nextDouble');
      let doubleVal1 = dart.dsend(rng1, 'nextDouble');
      expect$.Expect.isFalse(dart.dsend(results, 'contains', doubleVal0));
      dart.dsend(results, 'add', doubleVal0);
      expect$.Expect.isFalse(dart.dsend(results, 'contains', doubleVal1));
      dart.dsend(results, 'add', doubleVal1);
    }, VoidTodynamic());
    results = [];
    rng0 = math.Random.secure();
    for (let i = 0; i < 32; i++) {
      rng1 = math.Random.secure();
      checkDouble();
    }
    let cnt0 = 0;
    let cnt1 = 0;
    rng0 = math.Random.secure();
    for (let i = 0; i < 32; i++) {
      rng1 = math.Random.secure();
      cnt0 = cnt0 + (dart.test(dart.dsend(rng0, 'nextBool')) ? 1 : 0);
      cnt1 = cnt1 + (dart.test(dart.dsend(rng1, 'nextBool')) ? 1 : 0);
    }
    expect$.Expect.isTrue(cnt0 > 0 && cnt0 < 32);
    expect$.Expect.isTrue(cnt1 > 0 && cnt1 < 32);
  };
  dart.fn(random_secure_test.main, VoidTodynamic());
  // Exports:
  exports.random_secure_test = random_secure_test;
});
