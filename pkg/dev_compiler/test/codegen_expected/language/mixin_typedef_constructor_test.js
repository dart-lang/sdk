dart_library.library('language/mixin_typedef_constructor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_typedef_constructor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_typedef_constructor_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_typedef_constructor_test.A = class A extends core.Object {
    new(field) {
      this.field = field;
    }
  };
  dart.setSignature(mixin_typedef_constructor_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(mixin_typedef_constructor_test.A, [dart.dynamic])})
  });
  mixin_typedef_constructor_test.Mixin = class Mixin extends core.Object {
    new() {
      this.mixinField = 54;
    }
  };
  mixin_typedef_constructor_test.MyClass = class MyClass extends dart.mixin(mixin_typedef_constructor_test.A, mixin_typedef_constructor_test.Mixin) {
    new(field) {
      super.new(field);
    }
  };
  mixin_typedef_constructor_test.main = function() {
    let a = new mixin_typedef_constructor_test.MyClass(42);
    expect$.Expect.equals(42, a.field);
    expect$.Expect.equals(54, a.mixinField);
  };
  dart.fn(mixin_typedef_constructor_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_typedef_constructor_test = mixin_typedef_constructor_test;
});
