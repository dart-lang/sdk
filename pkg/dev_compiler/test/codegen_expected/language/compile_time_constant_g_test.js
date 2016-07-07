dart_library.library('language/compile_time_constant_g_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_g_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_g_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_g_test.A = class A extends core.Object {
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
  dart.defineNamedConstructor(compile_time_constant_g_test.A, 'named');
  dart.defineNamedConstructor(compile_time_constant_g_test.A, 'named2');
  dart.setSignature(compile_time_constant_g_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(compile_time_constant_g_test.A, [dart.dynamic]),
      named: dart.definiteFunctionType(compile_time_constant_g_test.A, [], [dart.dynamic]),
      named2: dart.definiteFunctionType(compile_time_constant_g_test.A, [], [dart.dynamic])
    })
  });
  compile_time_constant_g_test.B = class B extends compile_time_constant_g_test.A {
    new(x) {
      super.new(dart.dsend(x, '+', 10));
    }
    named_() {
      super.named();
    }
    named(x) {
      super.named(dart.dsend(x, '+', 10));
    }
    named2_() {
      super.named2();
    }
    named2(x) {
      super.named2(dart.dsend(x, '+', 10));
    }
  };
  dart.defineNamedConstructor(compile_time_constant_g_test.B, 'named_');
  dart.defineNamedConstructor(compile_time_constant_g_test.B, 'named');
  dart.defineNamedConstructor(compile_time_constant_g_test.B, 'named2_');
  dart.defineNamedConstructor(compile_time_constant_g_test.B, 'named2');
  dart.setSignature(compile_time_constant_g_test.B, {
    constructors: () => ({
      new: dart.definiteFunctionType(compile_time_constant_g_test.B, [dart.dynamic]),
      named_: dart.definiteFunctionType(compile_time_constant_g_test.B, []),
      named: dart.definiteFunctionType(compile_time_constant_g_test.B, [dart.dynamic]),
      named2_: dart.definiteFunctionType(compile_time_constant_g_test.B, []),
      named2: dart.definiteFunctionType(compile_time_constant_g_test.B, [dart.dynamic])
    })
  });
  compile_time_constant_g_test.b1 = dart.const(new compile_time_constant_g_test.B(0));
  compile_time_constant_g_test.b2 = dart.const(new compile_time_constant_g_test.B.named_());
  compile_time_constant_g_test.b3 = dart.const(new compile_time_constant_g_test.B.named(1));
  compile_time_constant_g_test.b4 = dart.const(new compile_time_constant_g_test.B.named2_());
  compile_time_constant_g_test.b5 = dart.const(new compile_time_constant_g_test.B.named2(3));
  compile_time_constant_g_test.main = function() {
    expect$.Expect.equals(10, compile_time_constant_g_test.b1.x);
    expect$.Expect.equals(null, compile_time_constant_g_test.b2.x);
    expect$.Expect.equals(11, compile_time_constant_g_test.b3.x);
    expect$.Expect.equals(2, compile_time_constant_g_test.b4.x);
    expect$.Expect.equals(13, compile_time_constant_g_test.b5.x);
  };
  dart.fn(compile_time_constant_g_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_g_test = compile_time_constant_g_test;
});
