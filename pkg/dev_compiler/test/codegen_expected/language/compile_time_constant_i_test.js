dart_library.library('language/compile_time_constant_i_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_i_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_i_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_i_test.A = class A extends core.Object {
    new(x) {
      this.x = x;
    }
    redirect(x) {
      A.prototype.new.call(this, dart.dsend(x, '+', 1));
    }
    optional(x) {
      if (x === void 0) x = 5;
      this.x = x;
    }
  };
  dart.defineNamedConstructor(compile_time_constant_i_test.A, 'redirect');
  dart.defineNamedConstructor(compile_time_constant_i_test.A, 'optional');
  dart.setSignature(compile_time_constant_i_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(compile_time_constant_i_test.A, [dart.dynamic]),
      redirect: dart.definiteFunctionType(compile_time_constant_i_test.A, [dart.dynamic]),
      optional: dart.definiteFunctionType(compile_time_constant_i_test.A, [], [dart.dynamic])
    })
  });
  compile_time_constant_i_test.B = class B extends compile_time_constant_i_test.A {
    new(x, y) {
      this.y = y;
      super.new(x);
    }
    redirect(x, y) {
      B.prototype.new.call(this, dart.dsend(x, '+', 22), dart.dsend(y, '+', 22));
    }
    redirect2(x, y) {
      B.prototype.redirect3.call(this, dart.dsend(x, '+', 122), dart.dsend(y, '+', 122));
    }
    redirect3(x, y) {
      this.y = y;
      super.redirect(x);
    }
    optional(x, y) {
      if (y === void 0) y = null;
      this.y = y;
      super.new(x);
    }
    optional2(x, y) {
      if (x === void 0) x = null;
      if (y === void 0) y = null;
      this.y = y;
      super.new(x);
    }
  };
  dart.defineNamedConstructor(compile_time_constant_i_test.B, 'redirect');
  dart.defineNamedConstructor(compile_time_constant_i_test.B, 'redirect2');
  dart.defineNamedConstructor(compile_time_constant_i_test.B, 'redirect3');
  dart.defineNamedConstructor(compile_time_constant_i_test.B, 'optional');
  dart.defineNamedConstructor(compile_time_constant_i_test.B, 'optional2');
  dart.setSignature(compile_time_constant_i_test.B, {
    constructors: () => ({
      new: dart.definiteFunctionType(compile_time_constant_i_test.B, [dart.dynamic, dart.dynamic]),
      redirect: dart.definiteFunctionType(compile_time_constant_i_test.B, [dart.dynamic, dart.dynamic]),
      redirect2: dart.definiteFunctionType(compile_time_constant_i_test.B, [dart.dynamic, dart.dynamic]),
      redirect3: dart.definiteFunctionType(compile_time_constant_i_test.B, [dart.dynamic, dart.dynamic]),
      optional: dart.definiteFunctionType(compile_time_constant_i_test.B, [dart.dynamic], [dart.dynamic]),
      optional2: dart.definiteFunctionType(compile_time_constant_i_test.B, [], [dart.dynamic, dart.dynamic])
    })
  });
  compile_time_constant_i_test.C = class C extends compile_time_constant_i_test.B {
    new(x, y, z) {
      this.z = z;
      super.new(x, y);
    }
    redirect(x, y, z) {
      C.prototype.new.call(this, dart.dsend(x, '+', 33), dart.dsend(y, '+', 33), dart.dsend(z, '+', 33));
    }
    redirect2(x, y, z) {
      C.prototype.redirect3.call(this, dart.dsend(x, '+', 333), dart.dsend(y, '+', 333), dart.dsend(z, '+', 333));
    }
    redirect3(x, y, z) {
      this.z = z;
      super.redirect2(x, y);
    }
    optional(x, y, z) {
      if (y === void 0) y = null;
      if (z === void 0) z = null;
      this.z = z;
      super.new(x, y);
    }
    optional2(x, y, z) {
      if (x === void 0) x = null;
      if (y === void 0) y = null;
      if (z === void 0) z = null;
      this.z = z;
      super.new(x, y);
    }
    optional3(z) {
      if (z === void 0) z = null;
      this.z = z;
      super.optional2();
    }
  };
  dart.defineNamedConstructor(compile_time_constant_i_test.C, 'redirect');
  dart.defineNamedConstructor(compile_time_constant_i_test.C, 'redirect2');
  dart.defineNamedConstructor(compile_time_constant_i_test.C, 'redirect3');
  dart.defineNamedConstructor(compile_time_constant_i_test.C, 'optional');
  dart.defineNamedConstructor(compile_time_constant_i_test.C, 'optional2');
  dart.defineNamedConstructor(compile_time_constant_i_test.C, 'optional3');
  dart.setSignature(compile_time_constant_i_test.C, {
    constructors: () => ({
      new: dart.definiteFunctionType(compile_time_constant_i_test.C, [dart.dynamic, dart.dynamic, dart.dynamic]),
      redirect: dart.definiteFunctionType(compile_time_constant_i_test.C, [dart.dynamic, dart.dynamic, dart.dynamic]),
      redirect2: dart.definiteFunctionType(compile_time_constant_i_test.C, [dart.dynamic, dart.dynamic, dart.dynamic]),
      redirect3: dart.definiteFunctionType(compile_time_constant_i_test.C, [dart.dynamic, dart.dynamic, dart.dynamic]),
      optional: dart.definiteFunctionType(compile_time_constant_i_test.C, [dart.dynamic], [dart.dynamic, dart.dynamic]),
      optional2: dart.definiteFunctionType(compile_time_constant_i_test.C, [], [dart.dynamic, dart.dynamic, dart.dynamic]),
      optional3: dart.definiteFunctionType(compile_time_constant_i_test.C, [], [dart.dynamic])
    })
  });
  compile_time_constant_i_test.a1 = dart.const(new compile_time_constant_i_test.A(499));
  compile_time_constant_i_test.a2 = dart.const(new compile_time_constant_i_test.A.redirect(10499));
  compile_time_constant_i_test.a3 = dart.const(new compile_time_constant_i_test.A.optional());
  compile_time_constant_i_test.a1b = dart.const(new compile_time_constant_i_test.A.redirect(498));
  compile_time_constant_i_test.a3b = dart.const(new compile_time_constant_i_test.A(5));
  compile_time_constant_i_test.b1 = dart.const(new compile_time_constant_i_test.B(99499, -99499));
  compile_time_constant_i_test.b2 = dart.const(new compile_time_constant_i_test.B.redirect(1234, 5678));
  compile_time_constant_i_test.b3 = dart.const(new compile_time_constant_i_test.B.redirect2(112233, 556677));
  compile_time_constant_i_test.b4 = dart.const(new compile_time_constant_i_test.B.redirect3(332211, 776655));
  compile_time_constant_i_test.b5 = dart.const(new compile_time_constant_i_test.B.optional(43526));
  compile_time_constant_i_test.b6 = dart.const(new compile_time_constant_i_test.B.optional2(8642, 9753));
  compile_time_constant_i_test.b3b = dart.const(new compile_time_constant_i_test.B(112233 + 122 + 1, 556677 + 122));
  compile_time_constant_i_test.b6b = dart.const(new compile_time_constant_i_test.B(8642, 9753));
  compile_time_constant_i_test.c1 = dart.const(new compile_time_constant_i_test.C(121, 232, 343));
  compile_time_constant_i_test.c2 = dart.const(new compile_time_constant_i_test.C.redirect(12321, 23432, 34543));
  compile_time_constant_i_test.c3 = dart.const(new compile_time_constant_i_test.C.redirect2(32123, 43234, 54345));
  compile_time_constant_i_test.c4 = dart.const(new compile_time_constant_i_test.C.redirect3(313, 424, 535));
  compile_time_constant_i_test.c5 = dart.const(new compile_time_constant_i_test.C.optional(191, 181, 171));
  compile_time_constant_i_test.c6 = dart.const(new compile_time_constant_i_test.C.optional(-191));
  compile_time_constant_i_test.c7 = dart.const(new compile_time_constant_i_test.C.optional2());
  compile_time_constant_i_test.c8 = dart.const(new compile_time_constant_i_test.C.optional3(9911));
  compile_time_constant_i_test.c3b = dart.const(new compile_time_constant_i_test.C(32123 + 333 + 122 + 1, 43234 + 333 + 122, 54345 + 333));
  compile_time_constant_i_test.main = function() {
    expect$.Expect.equals(499, compile_time_constant_i_test.a1.x);
    expect$.Expect.equals(10500, compile_time_constant_i_test.a2.x);
    expect$.Expect.equals(5, compile_time_constant_i_test.a3.x);
    expect$.Expect.identical(compile_time_constant_i_test.a1, compile_time_constant_i_test.a1b);
    expect$.Expect.identical(compile_time_constant_i_test.a3, compile_time_constant_i_test.a3b);
    expect$.Expect.equals(99499, compile_time_constant_i_test.b1.x);
    expect$.Expect.equals(-99499, compile_time_constant_i_test.b1.y);
    expect$.Expect.equals(1256, compile_time_constant_i_test.b2.x);
    expect$.Expect.equals(5700, compile_time_constant_i_test.b2.y);
    expect$.Expect.equals(112233 + 122 + 1, compile_time_constant_i_test.b3.x);
    expect$.Expect.equals(556677 + 122, compile_time_constant_i_test.b3.y);
    expect$.Expect.equals(332211 + 1, compile_time_constant_i_test.b4.x);
    expect$.Expect.equals(776655, compile_time_constant_i_test.b4.y);
    expect$.Expect.equals(43526, compile_time_constant_i_test.b5.x);
    expect$.Expect.equals(null, compile_time_constant_i_test.b5.y);
    expect$.Expect.equals(8642, compile_time_constant_i_test.b6.x);
    expect$.Expect.equals(9753, compile_time_constant_i_test.b6.y);
    expect$.Expect.identical(compile_time_constant_i_test.b3, compile_time_constant_i_test.b3b);
    expect$.Expect.identical(compile_time_constant_i_test.b6, compile_time_constant_i_test.b6b);
    expect$.Expect.equals(121, compile_time_constant_i_test.c1.x);
    expect$.Expect.equals(232, compile_time_constant_i_test.c1.y);
    expect$.Expect.equals(343, compile_time_constant_i_test.c1.z);
    expect$.Expect.equals(12321 + 33, compile_time_constant_i_test.c2.x);
    expect$.Expect.equals(23432 + 33, compile_time_constant_i_test.c2.y);
    expect$.Expect.equals(34543 + 33, compile_time_constant_i_test.c2.z);
    expect$.Expect.equals(32123 + 333 + 122 + 1, compile_time_constant_i_test.c3.x);
    expect$.Expect.equals(43234 + 333 + 122, compile_time_constant_i_test.c3.y);
    expect$.Expect.equals(54345 + 333, compile_time_constant_i_test.c3.z);
    expect$.Expect.equals(313 + 122 + 1, compile_time_constant_i_test.c4.x);
    expect$.Expect.equals(424 + 122, compile_time_constant_i_test.c4.y);
    expect$.Expect.equals(535, compile_time_constant_i_test.c4.z);
    expect$.Expect.equals(191, compile_time_constant_i_test.c5.x);
    expect$.Expect.equals(181, compile_time_constant_i_test.c5.y);
    expect$.Expect.equals(171, compile_time_constant_i_test.c5.z);
    expect$.Expect.equals(-191, compile_time_constant_i_test.c6.x);
    expect$.Expect.equals(null, compile_time_constant_i_test.c6.y);
    expect$.Expect.equals(null, compile_time_constant_i_test.c6.z);
    expect$.Expect.equals(null, compile_time_constant_i_test.c7.x);
    expect$.Expect.equals(null, compile_time_constant_i_test.c7.y);
    expect$.Expect.equals(null, compile_time_constant_i_test.c7.z);
    expect$.Expect.equals(null, compile_time_constant_i_test.c8.x);
    expect$.Expect.equals(null, compile_time_constant_i_test.c8.y);
    expect$.Expect.equals(9911, compile_time_constant_i_test.c8.z);
    expect$.Expect.identical(compile_time_constant_i_test.c3, compile_time_constant_i_test.c3b);
  };
  dart.fn(compile_time_constant_i_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_i_test = compile_time_constant_i_test;
});
