dart_library.library('language/regress_22822_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_22822_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_22822_test = Object.create(null);
  let VoidTonum = () => (VoidTonum = dart.constFn(dart.definiteFunctionType(core.num, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_22822_test.test = function(b) {
    try {
      for (let i = 0; i < 10; i++) {
        return dart.fn(() => i + dart.notNull(core.num._check(b)), VoidTonum());
      }
    } finally {
      b = 10;
    }
  };
  dart.fn(regress_22822_test.test, dynamicTodynamic());
  regress_22822_test.main = function() {
    let c = regress_22822_test.test(0);
    expect$.Expect.equals(10, dart.dcall(c));
  };
  dart.fn(regress_22822_test.main, VoidTodynamic());
  // Exports:
  exports.regress_22822_test = regress_22822_test;
});
