dart_library.library('language/new_expression_type_args_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__new_expression_type_args_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const new_expression_type_args_test_none_multi = Object.create(null);
  let A = () => (A = dart.constFn(new_expression_type_args_test_none_multi.A$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  new_expression_type_args_test_none_multi.A$ = dart.generic(T => {
    let AOfT = () => (AOfT = dart.constFn(new_expression_type_args_test_none_multi.A$(T)))();
    class A extends core.Object {
      m3() {
        return new (AOfT())();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({m3: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return A;
  });
  new_expression_type_args_test_none_multi.A = A();
  new_expression_type_args_test_none_multi.main = function() {
    let a = new new_expression_type_args_test_none_multi.A();
    a.m3();
  };
  dart.fn(new_expression_type_args_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.new_expression_type_args_test_none_multi = new_expression_type_args_test_none_multi;
});
