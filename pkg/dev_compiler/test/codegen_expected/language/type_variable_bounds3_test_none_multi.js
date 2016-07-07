dart_library.library('language/type_variable_bounds3_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__type_variable_bounds3_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_variable_bounds3_test_none_multi = Object.create(null);
  let A = () => (A = dart.constFn(type_variable_bounds3_test_none_multi.A$()))();
  let B = () => (B = dart.constFn(type_variable_bounds3_test_none_multi.B$()))();
  let BOfdouble$double = () => (BOfdouble$double = dart.constFn(type_variable_bounds3_test_none_multi.B$(core.double, core.double)))();
  let AOfint = () => (AOfint = dart.constFn(type_variable_bounds3_test_none_multi.A$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_variable_bounds3_test_none_multi.A$ = dart.generic(K => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  type_variable_bounds3_test_none_multi.A = A();
  type_variable_bounds3_test_none_multi.B$ = dart.generic((X, Y) => {
    class B extends core.Object {
      foo(x) {}
    }
    dart.addTypeTests(B);
    dart.setSignature(B, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
    });
    return B;
  });
  type_variable_bounds3_test_none_multi.B = B();
  type_variable_bounds3_test_none_multi.main = function() {
    let b = new (BOfdouble$double())();
    b.foo(new (AOfint())());
  };
  dart.fn(type_variable_bounds3_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.type_variable_bounds3_test_none_multi = type_variable_bounds3_test_none_multi;
});
