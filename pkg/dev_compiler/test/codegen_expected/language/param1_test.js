dart_library.library('language/param1_test', null, /* Imports */[
  'dart_sdk'
], function load__param1_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const param1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  param1_test.Param1Test = class Param1Test extends core.Object {
    static testMain() {
      return 0;
    }
  };
  dart.setSignature(param1_test.Param1Test, {
    statics: () => ({testMain: dart.definiteFunctionType(core.int, [])}),
    names: ['testMain']
  });
  param1_test.main = function() {
    param1_test.Param1Test.testMain();
  };
  dart.fn(param1_test.main, VoidTodynamic());
  // Exports:
  exports.param1_test = param1_test;
});
