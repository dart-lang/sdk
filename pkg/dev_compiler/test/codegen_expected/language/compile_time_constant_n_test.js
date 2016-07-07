dart_library.library('language/compile_time_constant_n_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_n_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_n_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_n_test.A = class A extends core.Object {
    new() {
    }
    ['=='](x) {
      return dart.equals(x, 499);
    }
  };
  dart.setSignature(compile_time_constant_n_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_n_test.A, [])})
  });
  compile_time_constant_n_test.a = dart.const(new compile_time_constant_n_test.A());
  let const$;
  compile_time_constant_n_test.main = function() {
    if (!dart.equals(const$ || (const$ = dart.const(new compile_time_constant_n_test.A())), 499)) expect$.Expect.isTrue("const equality failed");
    expect$.Expect.isTrue(dart.equals(compile_time_constant_n_test.a, 499));
  };
  dart.fn(compile_time_constant_n_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_n_test = compile_time_constant_n_test;
});
