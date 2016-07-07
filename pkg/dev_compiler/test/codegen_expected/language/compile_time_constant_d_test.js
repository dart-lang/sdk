dart_library.library('language/compile_time_constant_d_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_d_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_d_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_d_test.A = class A extends core.Object {
    new(z, tt) {
      this.z = z;
      this.y = 499;
      this.t = tt;
      this.x = 3;
    }
    named(z, t) {
      this.t = t;
      this.y = 400 + dart.notNull(core.num._check(z));
      this.z = z;
      this.x = 3;
    }
    named2(t, z, y, x) {
      this.x = t;
      this.y = z;
      this.z = y;
      this.t = x;
    }
    toString() {
      return dart.str`A ${this.x} ${this.y} ${this.z} ${this.t}`;
    }
  };
  dart.defineNamedConstructor(compile_time_constant_d_test.A, 'named');
  dart.defineNamedConstructor(compile_time_constant_d_test.A, 'named2');
  dart.setSignature(compile_time_constant_d_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(compile_time_constant_d_test.A, [dart.dynamic, dart.dynamic]),
      named: dart.definiteFunctionType(compile_time_constant_d_test.A, [dart.dynamic, dart.dynamic]),
      named2: dart.definiteFunctionType(compile_time_constant_d_test.A, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])
    })
  });
  compile_time_constant_d_test.a1 = dart.const(new compile_time_constant_d_test.A(99, 100));
  compile_time_constant_d_test.a2 = dart.const(new compile_time_constant_d_test.A.named(99, 100));
  compile_time_constant_d_test.a3 = dart.const(new compile_time_constant_d_test.A.named2(1, 2, 3, 4));
  compile_time_constant_d_test.main = function() {
    expect$.Expect.equals(3, compile_time_constant_d_test.a1.x);
    expect$.Expect.equals(499, compile_time_constant_d_test.a1.y);
    expect$.Expect.equals(99, compile_time_constant_d_test.a1.z);
    expect$.Expect.equals(100, compile_time_constant_d_test.a1.t);
    expect$.Expect.equals("A 3 499 99 100", compile_time_constant_d_test.a1.toString());
    expect$.Expect.isTrue(core.identical(compile_time_constant_d_test.a1, compile_time_constant_d_test.a2));
    expect$.Expect.equals(1, compile_time_constant_d_test.a3.x);
    expect$.Expect.equals(2, compile_time_constant_d_test.a3.y);
    expect$.Expect.equals(3, compile_time_constant_d_test.a3.z);
    expect$.Expect.equals(4, compile_time_constant_d_test.a3.t);
    expect$.Expect.equals("A 1 2 3 4", compile_time_constant_d_test.a3.toString());
  };
  dart.fn(compile_time_constant_d_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_d_test = compile_time_constant_d_test;
});
