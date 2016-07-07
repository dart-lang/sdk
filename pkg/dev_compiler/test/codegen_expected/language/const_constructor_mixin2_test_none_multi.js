dart_library.library('language/const_constructor_mixin2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__const_constructor_mixin2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const const_constructor_mixin2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_constructor_mixin2_test_none_multi.Mixin = class Mixin extends core.Object {
    new() {
      this.nonFinalField = null;
    }
  };
  const_constructor_mixin2_test_none_multi.A = class A extends core.Object {
    new(foo) {
    }
  };
  dart.setSignature(const_constructor_mixin2_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor_mixin2_test_none_multi.A, [dart.dynamic])})
  });
  const_constructor_mixin2_test_none_multi.B = class B extends const_constructor_mixin2_test_none_multi.A {
    new(foo) {
      super.new(foo);
    }
  };
  dart.setSignature(const_constructor_mixin2_test_none_multi.B, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor_mixin2_test_none_multi.B, [dart.dynamic])})
  });
  let const$;
  const_constructor_mixin2_test_none_multi.main = function() {
    let a = const$ || (const$ = dart.const(new const_constructor_mixin2_test_none_multi.B(42)));
  };
  dart.fn(const_constructor_mixin2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.const_constructor_mixin2_test_none_multi = const_constructor_mixin2_test_none_multi;
});
