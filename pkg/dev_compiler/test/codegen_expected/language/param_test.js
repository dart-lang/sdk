dart_library.library('language/param_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__param_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const param_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  param_test.Helper = class Helper extends core.Object {
    static foo(i) {
      let b = null;
      b = dart.notNull(i) + 1;
      return core.int._check(b);
    }
  };
  dart.setSignature(param_test.Helper, {
    statics: () => ({foo: dart.definiteFunctionType(core.int, [core.int])}),
    names: ['foo']
  });
  param_test.ParamTest = class ParamTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(2, param_test.Helper.foo(1));
    }
  };
  dart.setSignature(param_test.ParamTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  param_test.main = function() {
    param_test.ParamTest.testMain();
  };
  dart.fn(param_test.main, VoidTodynamic());
  // Exports:
  exports.param_test = param_test;
});
