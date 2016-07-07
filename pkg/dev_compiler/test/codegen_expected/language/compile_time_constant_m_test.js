dart_library.library('language/compile_time_constant_m_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_m_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_m_test = Object.create(null);
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  compile_time_constant_m_test.A = class A extends core.Object {
    new() {
    }
    foo(x) {
      if (x === void 0) x = const$ || (const$ = dart.const(new compile_time_constant_m_test.A()));
      return x;
    }
  };
  dart.setSignature(compile_time_constant_m_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_m_test.A, [])}),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])})
  });
  compile_time_constant_m_test.x = dart.const(new compile_time_constant_m_test.A());
  let const$0;
  compile_time_constant_m_test.foo = function(x) {
    if (x === void 0) x = const$0 || (const$0 = dart.const(new compile_time_constant_m_test.A()));
    return x;
  };
  dart.fn(compile_time_constant_m_test.foo, __Todynamic());
  compile_time_constant_m_test.main = function() {
    expect$.Expect.identical(compile_time_constant_m_test.x, compile_time_constant_m_test.foo());
    expect$.Expect.identical(compile_time_constant_m_test.x, compile_time_constant_m_test.x.foo());
  };
  dart.fn(compile_time_constant_m_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_m_test = compile_time_constant_m_test;
});
