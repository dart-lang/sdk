dart_library.library('language/bootstrap_test', null, /* Imports */[
  'dart_sdk'
], function load__bootstrap_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const bootstrap_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  bootstrap_test.BootstrapTest = class BootstrapTest extends core.Object {
    static testMain() {
      let obj = new core.Object();
      return obj;
    }
  };
  dart.setSignature(bootstrap_test.BootstrapTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  bootstrap_test.main = function() {
    bootstrap_test.BootstrapTest.testMain();
  };
  dart.fn(bootstrap_test.main, VoidTodynamic());
  // Exports:
  exports.bootstrap_test = bootstrap_test;
});
