dart_library.library('language/compile_time_constant_l_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_l_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_l_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_l_test.A = class A extends core.Object {
    new(x) {
      if (x === void 0) x = 499;
      this.x = x;
    }
  };
  dart.setSignature(compile_time_constant_l_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_l_test.A, [], [dart.dynamic])})
  });
  compile_time_constant_l_test.B = class B extends compile_time_constant_l_test.A {
    new() {
      this.z = 99;
      super.new();
    }
  };
  dart.setSignature(compile_time_constant_l_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_l_test.B, [])})
  });
  compile_time_constant_l_test.C = class C extends compile_time_constant_l_test.B {
    new(y) {
      this.y = y;
      super.new();
    }
  };
  dart.setSignature(compile_time_constant_l_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_l_test.C, [dart.dynamic])})
  });
  compile_time_constant_l_test.v = dart.const(new compile_time_constant_l_test.C(42));
  compile_time_constant_l_test.main = function() {
    expect$.Expect.equals(42, compile_time_constant_l_test.v.y);
    expect$.Expect.equals(499, compile_time_constant_l_test.v.x);
    expect$.Expect.equals(99, compile_time_constant_l_test.v.z);
  };
  dart.fn(compile_time_constant_l_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_l_test = compile_time_constant_l_test;
});
