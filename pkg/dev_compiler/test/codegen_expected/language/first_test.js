dart_library.library('language/first_test', null, /* Imports */[
  'dart_sdk'
], function load__first_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const first_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  first_test.FirstTest = class FirstTest extends core.Object {
    static testMain() {
      return 42;
    }
  };
  dart.setSignature(first_test.FirstTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  first_test.main = function() {
    first_test.FirstTest.testMain();
  };
  dart.fn(first_test.main, VoidTodynamic());
  // Exports:
  exports.first_test = first_test;
});
