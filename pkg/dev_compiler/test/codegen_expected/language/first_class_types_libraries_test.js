dart_library.library('language/first_class_types_libraries_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__first_class_types_libraries_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const first_class_types_libraries_test = Object.create(null);
  const first_class_types_lib1 = Object.create(null);
  const first_class_types_lib2 = Object.create(null);
  let C = () => (C = dart.constFn(first_class_types_libraries_test.C$()))();
  let COfA = () => (COfA = dart.constFn(first_class_types_libraries_test.C$(first_class_types_lib1.A)))();
  let COfA$ = () => (COfA$ = dart.constFn(first_class_types_libraries_test.C$(first_class_types_lib2.A)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  first_class_types_libraries_test.C$ = dart.generic(X => {
    class C extends core.Object {}
    dart.addTypeTests(C);
    return C;
  });
  first_class_types_libraries_test.C = C();
  first_class_types_libraries_test.sameType = function(a, b) {
    expect$.Expect.equals(dart.runtimeType(a), dart.runtimeType(b));
  };
  dart.fn(first_class_types_libraries_test.sameType, dynamicAnddynamicTodynamic());
  first_class_types_libraries_test.differentType = function(a, b) {
    expect$.Expect.notEquals(dart.runtimeType(a), dart.runtimeType(b));
  };
  dart.fn(first_class_types_libraries_test.differentType, dynamicAnddynamicTodynamic());
  first_class_types_libraries_test.main = function() {
    first_class_types_libraries_test.sameType(new first_class_types_lib1.A(), new first_class_types_lib1.A());
    first_class_types_libraries_test.differentType(new first_class_types_lib1.A(), new first_class_types_lib2.A());
    first_class_types_libraries_test.differentType(new (COfA())(), new (COfA$())());
  };
  dart.fn(first_class_types_libraries_test.main, VoidTodynamic());
  first_class_types_lib1.A = class A extends core.Object {};
  first_class_types_lib2.A = class A extends core.Object {};
  // Exports:
  exports.first_class_types_libraries_test = first_class_types_libraries_test;
  exports.first_class_types_lib1 = first_class_types_lib1;
  exports.first_class_types_lib2 = first_class_types_lib2;
});
