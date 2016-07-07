dart_library.library('language/regress_18435_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_18435_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_18435_test = Object.create(null);
  let __Tovoid = () => (__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [], [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_18435_test.main = function() {
    let MISSING_VALUE = "MISSING_VALUE";
    function foo(p1, p2) {
      if (p1 === void 0) p1 = MISSING_VALUE;
      if (p2 === void 0) p2 = MISSING_VALUE;
      expect$.Expect.equals("P1", p1);
      expect$.Expect.equals("P2", p2);
    }
    dart.fn(foo, __Tovoid());
    function bar(p1, p2) {
      if (p1 === void 0) p1 = "MISSING_VALUE";
      if (p2 === void 0) p2 = "MISSING_VALUE";
      expect$.Expect.equals("P1", p1);
      expect$.Expect.equals("P2", p2);
    }
    dart.fn(bar, __Tovoid());
    foo("P1", "P2");
    bar("P1", "P2");
  };
  dart.fn(regress_18435_test.main, VoidTodynamic());
  // Exports:
  exports.regress_18435_test = regress_18435_test;
});
