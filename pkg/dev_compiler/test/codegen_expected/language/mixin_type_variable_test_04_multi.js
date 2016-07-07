dart_library.library('language/mixin_type_variable_test_04_multi', null, /* Imports */[
  'dart_sdk'
], function load__mixin_type_variable_test_04_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_type_variable_test_04_multi = Object.create(null);
  let A = () => (A = dart.constFn(mixin_type_variable_test_04_multi.A$()))();
  let B = () => (B = dart.constFn(mixin_type_variable_test_04_multi.B$()))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  mixin_type_variable_test_04_multi.A$ = dart.generic(T => {
    class A extends core.Object {
      new() {
        this.field = null;
      }
    }
    dart.addTypeTests(A);
    return A;
  });
  mixin_type_variable_test_04_multi.A = A();
  mixin_type_variable_test_04_multi.B$ = dart.generic(T => {
    class B extends dart.mixin(core.Object, mixin_type_variable_test_04_multi.A$(T)) {}
    return B;
  });
  mixin_type_variable_test_04_multi.B = B();
  mixin_type_variable_test_04_multi.D = class D extends mixin_type_variable_test_04_multi.B$(core.int) {};
  dart.addSimpleTypeTests(mixin_type_variable_test_04_multi.D);
  mixin_type_variable_test_04_multi.E = class E extends dart.mixin(core.Object, mixin_type_variable_test_04_multi.A$(core.int)) {};
  mixin_type_variable_test_04_multi.main = function() {
    new mixin_type_variable_test_04_multi.D();
  };
  dart.fn(mixin_type_variable_test_04_multi.main, VoidTovoid());
  // Exports:
  exports.mixin_type_variable_test_04_multi = mixin_type_variable_test_04_multi;
});
