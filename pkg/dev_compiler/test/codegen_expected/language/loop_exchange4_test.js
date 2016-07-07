dart_library.library('language/loop_exchange4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__loop_exchange4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const loop_exchange4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  loop_exchange4_test.main = function() {
    let count = 0;
    for (let i = 0; i < 1; i++, count = count + i) {
    }
    let foo = null;
    for (let i = 0; i < 10; foo = i, i++) {
      if (i > 0) {
        expect$.Expect.equals(i - 1, foo);
      }
    }
  };
  dart.fn(loop_exchange4_test.main, VoidTodynamic());
  // Exports:
  exports.loop_exchange4_test = loop_exchange4_test;
});
