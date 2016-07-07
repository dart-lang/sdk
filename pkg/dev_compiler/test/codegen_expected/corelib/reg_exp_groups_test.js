dart_library.library('corelib/reg_exp_groups_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp_groups_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp_groups_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp_groups_test.RegExpGroupsTest = class RegExpGroupsTest extends core.Object {
    static testMain() {
      let match = core.RegExp.new("(a(b)((c|de)+))").firstMatch("abcde");
      let groups = match.groups(JSArrayOfint().of([0, 4, 2, 3]));
      expect$.Expect.equals('abcde', groups[dartx.get](0));
      expect$.Expect.equals('de', groups[dartx.get](1));
      expect$.Expect.equals('b', groups[dartx.get](2));
      expect$.Expect.equals('cde', groups[dartx.get](3));
    }
  };
  dart.setSignature(reg_exp_groups_test.RegExpGroupsTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  reg_exp_groups_test.main = function() {
    reg_exp_groups_test.RegExpGroupsTest.testMain();
  };
  dart.fn(reg_exp_groups_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp_groups_test = reg_exp_groups_test;
});
