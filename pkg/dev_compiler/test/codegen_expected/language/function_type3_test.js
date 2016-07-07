dart_library.library('language/function_type3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_type3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_type3_test = Object.create(null);
  let A = () => (A = dart.constFn(function_type3_test.A$()))();
  let B = () => (B = dart.constFn(function_type3_test.B$()))();
  let AOfint = () => (AOfint = dart.constFn(function_type3_test.A$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type3_test.A$ = dart.generic(T => {
    let BOfT = () => (BOfT = dart.constFn(function_type3_test.B$(T)))();
    class A extends core.Object {
      new() {
      }
      foo() {
        return new (BOfT())();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(function_type3_test.A$(T), [])}),
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return A;
  });
  function_type3_test.A = A();
  function_type3_test.B$ = dart.generic(T => {
    class B extends core.Object {
      bar() {
        return null;
      }
    }
    dart.addTypeTests(B);
    dart.setSignature(B, {
      methods: () => ({bar: dart.definiteFunctionType(T, [])})
    });
    return B;
  });
  function_type3_test.B = B();
  function_type3_test.F = dart.typedef('F', () => dart.functionType(dart.dynamic, []));
  function_type3_test.F2 = dart.typedef('F2', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  function_type3_test.main = function() {
    let f = dart.dload(new (AOfint())().foo(), 'bar');
    expect$.Expect.isTrue(function_type3_test.F.is(f));
    expect$.Expect.isFalse(function_type3_test.F2.is(f));
  };
  dart.fn(function_type3_test.main, VoidTodynamic());
  // Exports:
  exports.function_type3_test = function_type3_test;
});
