dart_library.library('language/return_this_type_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__return_this_type_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const return_this_type_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  return_this_type_test.A = class A extends core.Object {
    foo() {
      return this;
    }
  };
  dart.setSignature(return_this_type_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  return_this_type_test.B = class B extends return_this_type_test.A {};
  return_this_type_test.main = function() {
    expect$.Expect.isTrue(return_this_type_test.B.is(new return_this_type_test.B().foo()));
  };
  dart.fn(return_this_type_test.main, VoidTodynamic());
  // Exports:
  exports.return_this_type_test = return_this_type_test;
});
