dart_library.library('corelib/reg_exp_group_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp_group_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp_group_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp_group_test.RegExpGroupTest = class RegExpGroupTest extends core.Object {
    static testMain() {
      let match = core.RegExp.new("(a(b)((c|de)+))").firstMatch("abcde");
      expect$.Expect.equals('abcde', match.group(0));
      expect$.Expect.equals('abcde', match.group(1));
      expect$.Expect.equals('b', match.group(2));
      expect$.Expect.equals('cde', match.get(3));
      expect$.Expect.equals('de', match.get(4));
    }
  };
  dart.setSignature(reg_exp_group_test.RegExpGroupTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  reg_exp_group_test.main = function() {
    reg_exp_group_test.RegExpGroupTest.testMain();
  };
  dart.fn(reg_exp_group_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp_group_test = reg_exp_group_test;
});
