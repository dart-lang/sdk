dart_library.library('language/loop_exchange_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__loop_exchange_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const loop_exchange_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  loop_exchange_test.main = function() {
    let x = 1;
    let y = 2;
    for (let i = 0; i < 2; i++) {
      if (i == 1) expect$.Expect.equals(2, x);
      let tmp = x;
      x = y;
      y = tmp;
    }
  };
  dart.fn(loop_exchange_test.main, VoidTodynamic());
  // Exports:
  exports.loop_exchange_test = loop_exchange_test;
});
