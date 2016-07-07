dart_library.library('language/default_init_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__default_init_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const default_init_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  default_init_test.DefaultInitTest = class DefaultInitTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(0, default_init_test.A.a);
      expect$.Expect.equals(2, default_init_test.A.b);
      expect$.Expect.equals(null, default_init_test.A.c);
      let a1 = new default_init_test.A(42);
      expect$.Expect.equals(42, a1.d);
      expect$.Expect.equals(null, a1.e);
      let a2 = new default_init_test.A.named(43);
      expect$.Expect.equals(null, a2.d);
      expect$.Expect.equals(43, a2.e);
      expect$.Expect.equals(42, default_init_test.B.instance.x);
      expect$.Expect.equals(3, default_init_test.C.instance.z);
    }
  };
  dart.setSignature(default_init_test.DefaultInitTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  default_init_test.A = class A extends core.Object {
    new(val) {
      this.d = null;
      this.e = null;
      this.d = val;
    }
    named(val) {
      this.d = null;
      this.e = null;
      this.e = val;
    }
  };
  dart.defineNamedConstructor(default_init_test.A, 'named');
  dart.setSignature(default_init_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(default_init_test.A, [core.int]),
      named: dart.definiteFunctionType(default_init_test.A, [core.int])
    })
  });
  default_init_test.A.a = 0;
  default_init_test.A.b = 2;
  default_init_test.A.c = null;
  default_init_test.B = class B extends core.Object {
    new() {
      this.x = 41 + 1;
    }
  };
  dart.setSignature(default_init_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(default_init_test.B, [])})
  });
  dart.defineLazy(default_init_test.B, {
    get instance() {
      return dart.const(new default_init_test.B());
    }
  });
  default_init_test.C = class C extends core.Object {
    new() {
    }
  };
  dart.setSignature(default_init_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(default_init_test.C, [])})
  });
  dart.defineLazy(default_init_test.C, {
    get instance() {
      return dart.const(new default_init_test.D());
    }
  });
  default_init_test.D = class D extends core.Object {
    new() {
      this.z = 3;
    }
  };
  dart.setSignature(default_init_test.D, {
    constructors: () => ({new: dart.definiteFunctionType(default_init_test.D, [])})
  });
  default_init_test.main = function() {
    default_init_test.DefaultInitTest.testMain();
  };
  dart.fn(default_init_test.main, VoidTodynamic());
  // Exports:
  exports.default_init_test = default_init_test;
});
