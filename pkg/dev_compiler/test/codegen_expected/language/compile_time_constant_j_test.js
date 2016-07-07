dart_library.library('language/compile_time_constant_j_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_j_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_j_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_j_test.A = class A extends core.Object {
    new() {
      this.field = 499;
    }
  };
  dart.setSignature(compile_time_constant_j_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_j_test.A, [])})
  });
  compile_time_constant_j_test.x = 1 + 2;
  compile_time_constant_j_test.y = compile_time_constant_j_test.x;
  compile_time_constant_j_test.z = dart.const(new compile_time_constant_j_test.A());
  compile_time_constant_j_test.main = function() {
    expect$.Expect.equals(3, compile_time_constant_j_test.x);
    expect$.Expect.equals(3, compile_time_constant_j_test.y);
    expect$.Expect.equals(499, compile_time_constant_j_test.z.field);
  };
  dart.fn(compile_time_constant_j_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_j_test = compile_time_constant_j_test;
});
