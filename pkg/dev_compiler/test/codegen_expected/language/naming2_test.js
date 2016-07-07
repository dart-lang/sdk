dart_library.library('language/naming2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__naming2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const naming2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  naming2_test.A = class A extends core.Object {
    new(func) {
      this.function = func;
    }
  };
  dart.setSignature(naming2_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(naming2_test.A, [dart.dynamic])})
  });
  naming2_test.main = function() {
    let a = new naming2_test.A(499);
    expect$.Expect.equals(499, a.function);
  };
  dart.fn(naming2_test.main, VoidTodynamic());
  // Exports:
  exports.naming2_test = naming2_test;
});
