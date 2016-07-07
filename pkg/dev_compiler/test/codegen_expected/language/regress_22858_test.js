dart_library.library('language/regress_22858_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_22858_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_22858_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_22858_test.main = function() {
    let good = "good";
    function f1() {
      {
        let bad = "bad";
        function f2() {
          bad;
        }
        dart.fn(f2, VoidTodynamic());
      }
      expect$.Expect.equals("good", good);
      do {
        expect$.Expect.equals("good", good);
        let ugly = 0;
        function f3() {
          ugly;
        }
        dart.fn(f3, VoidTodynamic());
      } while (false);
    }
    dart.fn(f1, VoidTodynamic());
    f1();
  };
  dart.fn(regress_22858_test.main, VoidTodynamic());
  // Exports:
  exports.regress_22858_test = regress_22858_test;
});
