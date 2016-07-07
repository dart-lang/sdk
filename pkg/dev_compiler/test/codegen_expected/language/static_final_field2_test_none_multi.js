dart_library.library('language/static_final_field2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__static_final_field2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const static_final_field2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  static_final_field2_test_none_multi.A = class A extends core.Object {};
  static_final_field2_test_none_multi.A.x = 1;
  static_final_field2_test_none_multi.B = class B extends core.Object {
    new() {
      this.n = 5;
    }
  };
  dart.setSignature(static_final_field2_test_none_multi.B, {
    constructors: () => ({new: dart.definiteFunctionType(static_final_field2_test_none_multi.B, [])})
  });
  static_final_field2_test_none_multi.B.b = 3 + 5;
  static_final_field2_test_none_multi.main = function() {
    new static_final_field2_test_none_multi.B();
    core.print(static_final_field2_test_none_multi.B.b);
  };
  dart.fn(static_final_field2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.static_final_field2_test_none_multi = static_final_field2_test_none_multi;
});
