dart_library.library('language/inferrer_constructor5_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__inferrer_constructor5_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const inferrer_constructor5_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inferrer_constructor5_test_none_multi.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(inferrer_constructor5_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_constructor5_test_none_multi.A, [])})
  });
  inferrer_constructor5_test_none_multi.B = class B extends inferrer_constructor5_test_none_multi.A {
    new() {
      this.field = null;
      super.new();
      this.field = 42;
    }
  };
  dart.setSignature(inferrer_constructor5_test_none_multi.B, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_constructor5_test_none_multi.B, [])})
  });
  inferrer_constructor5_test_none_multi.main = function() {
  };
  dart.fn(inferrer_constructor5_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.inferrer_constructor5_test_none_multi = inferrer_constructor5_test_none_multi;
});
