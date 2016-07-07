dart_library.library('language/top_level_var_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__top_level_var_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const top_level_var_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  top_level_var_test.a = null;
  top_level_var_test.b = null;
  top_level_var_test.TopLevelVarTest = class TopLevelVarTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(null, top_level_var_test.a);
      expect$.Expect.equals(null, top_level_var_test.b);
      top_level_var_test.a = top_level_var_test.b = 100;
      top_level_var_test.b = dart.dsend(top_level_var_test.b, '+', 1);
      expect$.Expect.equals(100, top_level_var_test.a);
      expect$.Expect.equals(101, top_level_var_test.b);
      expect$.Expect.equals(111, top_level_var_test.x);
      expect$.Expect.equals(112, top_level_var_test.y);
    }
  };
  dart.setSignature(top_level_var_test.TopLevelVarTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  top_level_var_test.x = 2 * 55 + 1;
  top_level_var_test.y = top_level_var_test.x + 1;
  top_level_var_test.main = function() {
    top_level_var_test.TopLevelVarTest.testMain();
  };
  dart.fn(top_level_var_test.main, VoidTodynamic());
  // Exports:
  exports.top_level_var_test = top_level_var_test;
});
