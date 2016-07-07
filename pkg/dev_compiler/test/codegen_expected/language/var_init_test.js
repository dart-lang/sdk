dart_library.library('language/var_init_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__var_init_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const var_init_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  var_init_test.VarInitTest = class VarInitTest extends core.Object {
    static testMain() {
      for (let i = 0; i < 10; i++) {
        let x = null;
        expect$.Expect.equals(null, x);
        x = 1;
      }
    }
  };
  dart.setSignature(var_init_test.VarInitTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  var_init_test.main = function() {
    var_init_test.VarInitTest.testMain();
  };
  dart.fn(var_init_test.main, VoidTodynamic());
  // Exports:
  exports.var_init_test = var_init_test;
});
