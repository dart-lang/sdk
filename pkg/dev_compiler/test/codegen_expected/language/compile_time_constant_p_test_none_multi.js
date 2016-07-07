dart_library.library('language/compile_time_constant_p_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_p_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_p_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_p_test_none_multi.A = class A extends core.Object {
    new() {
      this.x = null;
    }
  };
  dart.setSignature(compile_time_constant_p_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_p_test_none_multi.A, [])})
  });
  compile_time_constant_p_test_none_multi.B = class B extends compile_time_constant_p_test_none_multi.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(compile_time_constant_p_test_none_multi.B, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_p_test_none_multi.B, [])})
  });
  compile_time_constant_p_test_none_multi.b = dart.const(new compile_time_constant_p_test_none_multi.B());
  compile_time_constant_p_test_none_multi.main = function() {
    expect$.Expect.equals(null, compile_time_constant_p_test_none_multi.b.x);
  };
  dart.fn(compile_time_constant_p_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_p_test_none_multi = compile_time_constant_p_test_none_multi;
});
