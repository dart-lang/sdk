dart_library.library('language/top_level_method_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__top_level_method_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const top_level_method_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  top_level_method_test.untypedTopLevel = function() {
    return 1;
  };
  dart.fn(top_level_method_test.untypedTopLevel, VoidTodynamic());
  top_level_method_test.TopLevelMethodTest = class TopLevelMethodTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(1, top_level_method_test.untypedTopLevel());
    }
  };
  dart.setSignature(top_level_method_test.TopLevelMethodTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  top_level_method_test.main = function() {
    top_level_method_test.TopLevelMethodTest.testMain();
  };
  dart.fn(top_level_method_test.main, VoidTodynamic());
  // Exports:
  exports.top_level_method_test = top_level_method_test;
});
