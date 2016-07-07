dart_library.library('language/compile_time_constant_f_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_f_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_f_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_f_test.A = class A extends core.Object {
    new(x) {
      this.x = x;
    }
    named(x) {
      if (x === void 0) x = null;
      this.x = x;
    }
    named2(x) {
      if (x === void 0) x = 2;
      this.x = x;
    }
  };
  dart.defineNamedConstructor(compile_time_constant_f_test.A, 'named');
  dart.defineNamedConstructor(compile_time_constant_f_test.A, 'named2');
  dart.setSignature(compile_time_constant_f_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(compile_time_constant_f_test.A, [dart.dynamic]),
      named: dart.definiteFunctionType(compile_time_constant_f_test.A, [], [dart.dynamic]),
      named2: dart.definiteFunctionType(compile_time_constant_f_test.A, [], [dart.dynamic])
    })
  });
  compile_time_constant_f_test.a1 = dart.const(new compile_time_constant_f_test.A(0));
  compile_time_constant_f_test.a2 = dart.const(new compile_time_constant_f_test.A.named());
  compile_time_constant_f_test.a3 = dart.const(new compile_time_constant_f_test.A.named(1));
  compile_time_constant_f_test.a4 = dart.const(new compile_time_constant_f_test.A.named2());
  compile_time_constant_f_test.a5 = dart.const(new compile_time_constant_f_test.A.named2(3));
  compile_time_constant_f_test.main = function() {
    expect$.Expect.equals(0, compile_time_constant_f_test.a1.x);
    expect$.Expect.equals(null, compile_time_constant_f_test.a2.x);
    expect$.Expect.equals(1, compile_time_constant_f_test.a3.x);
    expect$.Expect.equals(2, compile_time_constant_f_test.a4.x);
    expect$.Expect.equals(3, compile_time_constant_f_test.a5.x);
  };
  dart.fn(compile_time_constant_f_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_f_test = compile_time_constant_f_test;
});
