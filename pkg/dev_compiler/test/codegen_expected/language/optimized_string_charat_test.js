dart_library.library('language/optimized_string_charat_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__optimized_string_charat_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const optimized_string_charat_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  optimized_string_charat_test.a = "abc";
  optimized_string_charat_test.b = "øbc";
  dart.defineLazy(optimized_string_charat_test, {
    get c() {
      return core.String.fromCharCodes(JSArrayOfint().of([123, 456, 789]));
    },
    set c(_) {}
  });
  optimized_string_charat_test.test_charat = function(s, i) {
    return dart.dindex(s, i);
  };
  dart.fn(optimized_string_charat_test.test_charat, dynamicAnddynamicTodynamic());
  optimized_string_charat_test.test_const_str = function(i) {
    return "abc"[dartx.get](core.int._check(i));
  };
  dart.fn(optimized_string_charat_test.test_const_str, dynamicTodynamic());
  optimized_string_charat_test.test_const_index = function(s) {
    return dart.dindex(s, 0);
  };
  dart.fn(optimized_string_charat_test.test_const_index, dynamicTodynamic());
  optimized_string_charat_test.test_const_index2 = function(s) {
    return dart.dindex(s, 3);
  };
  dart.fn(optimized_string_charat_test.test_const_index2, dynamicTodynamic());
  optimized_string_charat_test.main = function() {
    expect$.Expect.equals("a", optimized_string_charat_test.test_charat(optimized_string_charat_test.a, 0));
    for (let i = 0; i < 20; i++)
      optimized_string_charat_test.test_charat(optimized_string_charat_test.a, 0);
    expect$.Expect.equals("a", optimized_string_charat_test.test_charat(optimized_string_charat_test.a, 0));
    expect$.Expect.equals("b", optimized_string_charat_test.test_charat(optimized_string_charat_test.a, 1));
    expect$.Expect.equals("c", optimized_string_charat_test.test_charat(optimized_string_charat_test.a, 2));
    expect$.Expect.throws(dart.fn(() => optimized_string_charat_test.test_charat(optimized_string_charat_test.a, 3), VoidTovoid()));
    expect$.Expect.equals("a", optimized_string_charat_test.test_const_str(0));
    for (let i = 0; i < 20; i++)
      optimized_string_charat_test.test_const_str(0);
    expect$.Expect.equals("a", optimized_string_charat_test.test_const_str(0));
    expect$.Expect.equals("b", optimized_string_charat_test.test_const_str(1));
    expect$.Expect.equals("c", optimized_string_charat_test.test_const_str(2));
    expect$.Expect.throws(dart.fn(() => optimized_string_charat_test.test_const_str(3), VoidTovoid()));
    expect$.Expect.equals("a", optimized_string_charat_test.test_const_index(optimized_string_charat_test.a));
    for (let i = 0; i < 20; i++)
      optimized_string_charat_test.test_const_index(optimized_string_charat_test.a);
    expect$.Expect.equals("a", optimized_string_charat_test.test_const_index(optimized_string_charat_test.a));
    expect$.Expect.equals("ø", optimized_string_charat_test.test_const_index(optimized_string_charat_test.b));
    expect$.Expect.equals(core.String.fromCharCodes(JSArrayOfint().of([123])), optimized_string_charat_test.test_const_index(optimized_string_charat_test.c));
    expect$.Expect.throws(dart.fn(() => optimized_string_charat_test.test_const_index2(optimized_string_charat_test.a), VoidTovoid()));
    expect$.Expect.equals("ø", optimized_string_charat_test.test_charat(optimized_string_charat_test.b, 0));
    for (let i = 0; i < 20; i++)
      optimized_string_charat_test.test_charat(optimized_string_charat_test.b, 0);
    expect$.Expect.equals("ø", optimized_string_charat_test.test_charat(optimized_string_charat_test.b, 0));
    expect$.Expect.equals("b", optimized_string_charat_test.test_charat(optimized_string_charat_test.b, 1));
    expect$.Expect.equals("c", optimized_string_charat_test.test_charat(optimized_string_charat_test.b, 2));
    expect$.Expect.throws(dart.fn(() => optimized_string_charat_test.test_charat(optimized_string_charat_test.b, 3), VoidTovoid()));
    expect$.Expect.equals(core.String.fromCharCodes(JSArrayOfint().of([123])), optimized_string_charat_test.test_charat(optimized_string_charat_test.c, 0));
    for (let i = 0; i < 20; i++)
      optimized_string_charat_test.test_charat(optimized_string_charat_test.c, 0);
    expect$.Expect.equals(core.String.fromCharCodes(JSArrayOfint().of([123])), optimized_string_charat_test.test_charat(optimized_string_charat_test.c, 0));
    expect$.Expect.equals(core.String.fromCharCodes(JSArrayOfint().of([456])), optimized_string_charat_test.test_charat(optimized_string_charat_test.c, 1));
    expect$.Expect.equals(core.String.fromCharCodes(JSArrayOfint().of([789])), optimized_string_charat_test.test_charat(optimized_string_charat_test.c, 2));
    expect$.Expect.throws(dart.fn(() => optimized_string_charat_test.test_charat(optimized_string_charat_test.c, 3), VoidTovoid()));
  };
  dart.fn(optimized_string_charat_test.main, VoidTodynamic());
  // Exports:
  exports.optimized_string_charat_test = optimized_string_charat_test;
});
