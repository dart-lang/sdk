dart_library.library('language/mixin_type_parameters_errors_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__mixin_type_parameters_errors_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_type_parameters_errors_test_none_multi = Object.create(null);
  let S = () => (S = dart.constFn(mixin_type_parameters_errors_test_none_multi.S$()))();
  let M = () => (M = dart.constFn(mixin_type_parameters_errors_test_none_multi.M$()))();
  let A = () => (A = dart.constFn(mixin_type_parameters_errors_test_none_multi.A$()))();
  let F = () => (F = dart.constFn(mixin_type_parameters_errors_test_none_multi.F$()))();
  let AOfint = () => (AOfint = dart.constFn(mixin_type_parameters_errors_test_none_multi.A$(core.int)))();
  let FOfint = () => (FOfint = dart.constFn(mixin_type_parameters_errors_test_none_multi.F$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_type_parameters_errors_test_none_multi.S$ = dart.generic(T => {
    class S extends core.Object {}
    dart.addTypeTests(S);
    return S;
  });
  mixin_type_parameters_errors_test_none_multi.S = S();
  mixin_type_parameters_errors_test_none_multi.M$ = dart.generic(U => {
    class M extends core.Object {}
    dart.addTypeTests(M);
    return M;
  });
  mixin_type_parameters_errors_test_none_multi.M = M();
  mixin_type_parameters_errors_test_none_multi.A$ = dart.generic(X => {
    class A extends dart.mixin(mixin_type_parameters_errors_test_none_multi.S$(core.int), mixin_type_parameters_errors_test_none_multi.M$(core.double)) {}
    return A;
  });
  mixin_type_parameters_errors_test_none_multi.A = A();
  mixin_type_parameters_errors_test_none_multi.F$ = dart.generic(X => {
    class F extends dart.mixin(mixin_type_parameters_errors_test_none_multi.S$(X), mixin_type_parameters_errors_test_none_multi.M$(X)) {
      new() {
        super.new();
      }
    }
    return F;
  });
  mixin_type_parameters_errors_test_none_multi.F = F();
  mixin_type_parameters_errors_test_none_multi.main = function() {
    let a = null;
    a = new mixin_type_parameters_errors_test_none_multi.A();
    a = new (AOfint())();
    a = new (FOfint())();
  };
  dart.fn(mixin_type_parameters_errors_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.mixin_type_parameters_errors_test_none_multi = mixin_type_parameters_errors_test_none_multi;
});
