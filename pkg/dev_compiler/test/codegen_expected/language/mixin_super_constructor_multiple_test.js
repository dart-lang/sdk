dart_library.library('language/mixin_super_constructor_multiple_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_super_constructor_multiple_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_super_constructor_multiple_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_super_constructor_multiple_test.S = class S extends core.Object {
    foo() {
      this.i = 1742;
    }
  };
  dart.defineNamedConstructor(mixin_super_constructor_multiple_test.S, 'foo');
  dart.setSignature(mixin_super_constructor_multiple_test.S, {
    constructors: () => ({foo: dart.definiteFunctionType(mixin_super_constructor_multiple_test.S, [])})
  });
  mixin_super_constructor_multiple_test.M1 = class M1 extends core.Object {};
  mixin_super_constructor_multiple_test.M2 = class M2 extends core.Object {};
  mixin_super_constructor_multiple_test.C = class C extends dart.mixin(mixin_super_constructor_multiple_test.S, mixin_super_constructor_multiple_test.M1, mixin_super_constructor_multiple_test.M2) {
    foo() {
      super.foo();
    }
  };
  dart.defineNamedConstructor(mixin_super_constructor_multiple_test.C, 'foo');
  dart.setSignature(mixin_super_constructor_multiple_test.C, {
    constructors: () => ({foo: dart.definiteFunctionType(mixin_super_constructor_multiple_test.C, [])})
  });
  mixin_super_constructor_multiple_test.main = function() {
    expect$.Expect.equals(1742, new mixin_super_constructor_multiple_test.C.foo().i);
  };
  dart.fn(mixin_super_constructor_multiple_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_super_constructor_multiple_test = mixin_super_constructor_multiple_test;
});
