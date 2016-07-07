dart_library.library('language/final_param_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__final_param_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const final_param_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  final_param_test_none_multi.A = class A extends core.Object {
    static test(x) {}
  };
  dart.setSignature(final_param_test_none_multi.A, {
    statics: () => ({test: dart.definiteFunctionType(dart.void, [dart.dynamic])}),
    names: ['test']
  });
  final_param_test_none_multi.main = function() {
    final_param_test_none_multi.A.test(1);
  };
  dart.fn(final_param_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.final_param_test_none_multi = final_param_test_none_multi;
});
