dart_library.library('corelib/reg_exp1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp1_test.RegExp1Test = class RegExp1Test extends core.Object {
    static testMain() {
      let exp1 = core.RegExp.new("bar|foo");
      expect$.Expect.equals(true, exp1.hasMatch("foo"));
      expect$.Expect.equals(true, exp1.hasMatch("bar"));
      expect$.Expect.equals(false, exp1.hasMatch("gim"));
      expect$.Expect.equals(true, exp1.hasMatch("just foo"));
      expect$.Expect.equals("bar|foo", exp1.pattern);
      expect$.Expect.equals(false, exp1.isMultiLine);
      expect$.Expect.equals(true, exp1.isCaseSensitive);
      let exp2 = core.RegExp.new("o+", {caseSensitive: false});
      expect$.Expect.equals(true, exp2.hasMatch("this looks good"));
      expect$.Expect.equals(true, exp2.hasMatch("fOO"));
      expect$.Expect.equals(false, exp2.hasMatch("bar"));
      expect$.Expect.equals("o+", exp2.pattern);
      expect$.Expect.equals(false, exp2.isCaseSensitive);
      expect$.Expect.equals(false, exp2.isMultiLine);
    }
  };
  dart.setSignature(reg_exp1_test.RegExp1Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  reg_exp1_test.main = function() {
    reg_exp1_test.RegExp1Test.testMain();
  };
  dart.fn(reg_exp1_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp1_test = reg_exp1_test;
});
