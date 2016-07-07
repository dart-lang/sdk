dart_library.library('language/reg_exp3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp3_test.RegExp3Test = class RegExp3Test extends core.Object {
    static testMain() {
      let i = 2000;
      try {
        let exp = core.RegExp.new("[");
        i = 100;
      } catch (e) {
        if (core.FormatException.is(e)) {
          i = 0;
        } else
          throw e;
      }

      expect$.Expect.equals(0, i);
    }
  };
  dart.setSignature(reg_exp3_test.RegExp3Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  reg_exp3_test.main = function() {
    reg_exp3_test.RegExp3Test.testMain();
  };
  dart.fn(reg_exp3_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp3_test = reg_exp3_test;
});
