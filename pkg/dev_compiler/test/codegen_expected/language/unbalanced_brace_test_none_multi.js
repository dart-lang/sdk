dart_library.library('language/unbalanced_brace_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__unbalanced_brace_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unbalanced_brace_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  unbalanced_brace_test_none_multi.A = class A extends core.Object {
    m() {}
  };
  dart.setSignature(unbalanced_brace_test_none_multi.A, {
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [])})
  });
  unbalanced_brace_test_none_multi.B = class B extends core.Object {};
  unbalanced_brace_test_none_multi.main = function() {
    new unbalanced_brace_test_none_multi.A();
    new unbalanced_brace_test_none_multi.B();
  };
  dart.fn(unbalanced_brace_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.unbalanced_brace_test_none_multi = unbalanced_brace_test_none_multi;
});
