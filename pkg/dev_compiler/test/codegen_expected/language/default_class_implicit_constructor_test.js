dart_library.library('language/default_class_implicit_constructor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__default_class_implicit_constructor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const default_class_implicit_constructor_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  default_class_implicit_constructor_test.A = class A extends core.Object {
    static new() {
      return new default_class_implicit_constructor_test.B();
    }
  };
  dart.setSignature(default_class_implicit_constructor_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(default_class_implicit_constructor_test.A, [])})
  });
  default_class_implicit_constructor_test.B = class B extends core.Object {};
  default_class_implicit_constructor_test.B[dart.implements] = () => [default_class_implicit_constructor_test.A];
  default_class_implicit_constructor_test.main = function() {
    let val = default_class_implicit_constructor_test.A.new();
    expect$.Expect.equals(true, default_class_implicit_constructor_test.A.is(val));
    expect$.Expect.equals(true, default_class_implicit_constructor_test.B.is(val));
  };
  dart.fn(default_class_implicit_constructor_test.main, VoidTodynamic());
  // Exports:
  exports.default_class_implicit_constructor_test = default_class_implicit_constructor_test;
});
