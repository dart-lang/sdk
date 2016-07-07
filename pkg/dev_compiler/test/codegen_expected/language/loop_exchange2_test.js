dart_library.library('language/loop_exchange2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__loop_exchange2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const loop_exchange2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  loop_exchange2_test.main = function() {
    let a = 1;
    let b = 2;
    let c = 3;
    let d = 4;
    let e = 5;
    for (let i = 0; i < 2; i++) {
      if (i == 1) {
        expect$.Expect.equals(4, e);
        expect$.Expect.equals(3, d);
        expect$.Expect.equals(8, c);
        expect$.Expect.equals(1, b);
        expect$.Expect.equals(32, a);
      }
      let f = null;
      let k = null;
      if (i < 20) {
        f = (b & c | ~b & d) >>> 0;
        k = 1518500249;
      } else if (i < 40) {
        f = (b ^ c ^ d) >>> 0;
        k = 1859775393;
      } else if (i < 60) {
        f = (b & c | b & d | c & d) >>> 0;
        k = 2400959708;
      } else {
        f = (b ^ c ^ d) >>> 0;
        k = 3395469782;
      }
      let temp = a << 5 >>> 0;
      e = d;
      d = c;
      c = b << 2 >>> 0;
      b = a;
      a = temp;
    }
  };
  dart.fn(loop_exchange2_test.main, VoidTodynamic());
  // Exports:
  exports.loop_exchange2_test = loop_exchange2_test;
});
