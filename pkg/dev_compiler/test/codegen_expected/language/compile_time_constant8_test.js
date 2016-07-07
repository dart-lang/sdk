dart_library.library('language/compile_time_constant8_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant8_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant8_test = Object.create(null);
  let A = () => (A = dart.constFn(compile_time_constant8_test.A$()))();
  let AOfint = () => (AOfint = dart.constFn(compile_time_constant8_test.A$(core.int)))();
  let AOfdouble = () => (AOfdouble = dart.constFn(compile_time_constant8_test.A$(core.double)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant8_test.A$ = dart.generic(T => {
    class A extends core.Object {
      new() {
      }
      toString() {
        return "a";
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(compile_time_constant8_test.A$(T), [])})
    });
    return A;
  });
  compile_time_constant8_test.A = A();
  compile_time_constant8_test.a = dart.const(new (AOfint())());
  compile_time_constant8_test.b = dart.const(new (AOfdouble())());
  compile_time_constant8_test.list1 = dart.constList([1, 2], core.int);
  compile_time_constant8_test.list2 = dart.constList([1, 2], dart.dynamic);
  compile_time_constant8_test.main = function() {
    expect$.Expect.isFalse(core.identical(compile_time_constant8_test.a, compile_time_constant8_test.b));
    expect$.Expect.isFalse(core.identical(compile_time_constant8_test.list1, compile_time_constant8_test.list2));
  };
  dart.fn(compile_time_constant8_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant8_test = compile_time_constant8_test;
});
