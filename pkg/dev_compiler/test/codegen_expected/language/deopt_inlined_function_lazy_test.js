dart_library.library('language/deopt_inlined_function_lazy_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deopt_inlined_function_lazy_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deopt_inlined_function_lazy_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deopt_inlined_function_lazy_test.call_native = function(x) {
    try {
      return dart.dsend(x, '+', 12342353257893275483274832);
    } finally {
    }
  };
  dart.fn(deopt_inlined_function_lazy_test.call_native, dynamicTodynamic());
  deopt_inlined_function_lazy_test.bar = function(x) {
    if (dart.test(dart.dsend(x, '<', 0))) deopt_inlined_function_lazy_test.call_native(x);
    x = 42;
    return x;
  };
  dart.fn(deopt_inlined_function_lazy_test.bar, dynamicTodynamic());
  deopt_inlined_function_lazy_test.foo = function(x) {
    x = deopt_inlined_function_lazy_test.bar(x);
    return x;
  };
  dart.fn(deopt_inlined_function_lazy_test.foo, dynamicTodynamic());
  deopt_inlined_function_lazy_test.main = function() {
    expect$.Expect.equals(42, deopt_inlined_function_lazy_test.foo(1));
    for (let i = 0; i < 20; i++)
      deopt_inlined_function_lazy_test.foo(7);
    expect$.Expect.equals(42, deopt_inlined_function_lazy_test.foo(2));
    expect$.Expect.equals(42, deopt_inlined_function_lazy_test.foo(-1));
  };
  dart.fn(deopt_inlined_function_lazy_test.main, VoidTodynamic());
  // Exports:
  exports.deopt_inlined_function_lazy_test = deopt_inlined_function_lazy_test;
});
