dart_library.library('language/optimized_isempty_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__optimized_isempty_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const optimized_isempty_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  optimized_isempty_test.test = function(s) {
    return dart.dload(s, 'isEmpty');
  };
  dart.fn(optimized_isempty_test.test, dynamicTodynamic());
  optimized_isempty_test.main = function() {
    let x = "abc";
    let y = JSArrayOfint().of([123, 12345, 765]);
    expect$.Expect.equals(false, optimized_isempty_test.test(x));
    expect$.Expect.equals(false, optimized_isempty_test.test(y));
    for (let i = 0; i < 20; i++)
      optimized_isempty_test.test(x);
    expect$.Expect.equals(false, optimized_isempty_test.test(x));
    expect$.Expect.equals(false, optimized_isempty_test.test(y));
  };
  dart.fn(optimized_isempty_test.main, VoidTodynamic());
  // Exports:
  exports.optimized_isempty_test = optimized_isempty_test;
});
