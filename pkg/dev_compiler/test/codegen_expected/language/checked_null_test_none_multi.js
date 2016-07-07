dart_library.library('language/checked_null_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__checked_null_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const checked_null_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  checked_null_test_none_multi.A = class A extends core.Object {
    new() {
      this.b = null;
      this.a = null;
    }
  };
  dart.setSignature(checked_null_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(checked_null_test_none_multi.A, [])})
  });
  checked_null_test_none_multi.main = function() {
  };
  dart.fn(checked_null_test_none_multi.main, VoidTodynamic());
  checked_null_test_none_multi.bar = function() {
  };
  dart.fn(checked_null_test_none_multi.bar, VoidTodynamic());
  // Exports:
  exports.checked_null_test_none_multi = checked_null_test_none_multi;
});
