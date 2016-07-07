dart_library.library('language/mixin_type_variable_test_03_multi', null, /* Imports */[
  'dart_sdk'
], function load__mixin_type_variable_test_03_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_type_variable_test_03_multi = Object.create(null);
  let A = () => (A = dart.constFn(mixin_type_variable_test_03_multi.A$()))();
  let B = () => (B = dart.constFn(mixin_type_variable_test_03_multi.B$()))();
  let C = () => (C = dart.constFn(mixin_type_variable_test_03_multi.C$()))();
  let COfnum = () => (COfnum = dart.constFn(mixin_type_variable_test_03_multi.C$(core.num)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  mixin_type_variable_test_03_multi.A$ = dart.generic(T => {
    class A extends core.Object {
      new() {
        this.field = null;
      }
    }
    dart.addTypeTests(A);
    return A;
  });
  mixin_type_variable_test_03_multi.A = A();
  mixin_type_variable_test_03_multi.B$ = dart.generic(T => {
    class B extends dart.mixin(core.Object, mixin_type_variable_test_03_multi.A$(T)) {}
    return B;
  });
  mixin_type_variable_test_03_multi.B = B();
  mixin_type_variable_test_03_multi.C$ = dart.generic(T => {
    class C extends mixin_type_variable_test_03_multi.B$(T) {}
    return C;
  });
  mixin_type_variable_test_03_multi.C = C();
  mixin_type_variable_test_03_multi.E = class E extends dart.mixin(core.Object, mixin_type_variable_test_03_multi.A$(core.int)) {};
  mixin_type_variable_test_03_multi.main = function() {
    new (COfnum())();
  };
  dart.fn(mixin_type_variable_test_03_multi.main, VoidTovoid());
  // Exports:
  exports.mixin_type_variable_test_03_multi = mixin_type_variable_test_03_multi;
});
