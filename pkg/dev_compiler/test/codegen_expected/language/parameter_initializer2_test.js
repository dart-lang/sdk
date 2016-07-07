dart_library.library('language/parameter_initializer2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__parameter_initializer2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const parameter_initializer2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  parameter_initializer2_test.ParameterInitializer2Test = class ParameterInitializer2Test extends core.Object {
    static testMain() {
      let a = new parameter_initializer2_test.A(123);
      expect$.Expect.equals(123, a.x);
      let b = new parameter_initializer2_test.B(123);
      expect$.Expect.equals(123, b.x);
      let c = new parameter_initializer2_test.C(123);
      expect$.Expect.equals(123, c.x);
      let d = new parameter_initializer2_test.D(123);
      expect$.Expect.equals(123, d.x);
      let e = new parameter_initializer2_test.E(1);
      expect$.Expect.equals(4, e.x);
      let f = new parameter_initializer2_test.F(1, 2, 3, 4);
      expect$.Expect.equals(4, f.z);
    }
  };
  dart.setSignature(parameter_initializer2_test.ParameterInitializer2Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  parameter_initializer2_test.A = class A extends core.Object {
    new(x) {
      this.x = x;
    }
  };
  dart.setSignature(parameter_initializer2_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(parameter_initializer2_test.A, [core.int])})
  });
  parameter_initializer2_test.B = class B extends core.Object {
    new(x) {
      this.x = x;
    }
  };
  dart.setSignature(parameter_initializer2_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(parameter_initializer2_test.B, [core.int])})
  });
  parameter_initializer2_test.C = class C extends core.Object {
    new(x) {
      this.x = x;
    }
  };
  dart.setSignature(parameter_initializer2_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(parameter_initializer2_test.C, [core.int])})
  });
  parameter_initializer2_test.D = class D extends core.Object {
    new(x) {
      this.x = x;
    }
  };
  dart.setSignature(parameter_initializer2_test.D, {
    constructors: () => ({new: dart.definiteFunctionType(parameter_initializer2_test.D, [dart.dynamic])})
  });
  parameter_initializer2_test.E = class E extends core.Object {
    new(x) {
      this.x = x;
      let myVar = dart.notNull(this.x) * 2;
      this.x = myVar + 1;
      this.x = myVar + 2;
      let foo = dart.notNull(this.x) + 1;
    }
  };
  dart.setSignature(parameter_initializer2_test.E, {
    constructors: () => ({new: dart.definiteFunctionType(parameter_initializer2_test.E, [core.int])})
  });
  parameter_initializer2_test.F = class F extends core.Object {
    new(x, y_, w, z) {
      this.y_ = y_;
      this.z = z;
      this.x_ = core.int._check(x);
      this.w_ = w;
      this.az_ = null;
    }
    foobar(z, x_, az_) {
      this.z = z;
      this.x_ = x_;
      this.az_ = az_;
      this.y_ = null;
      this.w_ = null;
    }
  };
  dart.defineNamedConstructor(parameter_initializer2_test.F, 'foobar');
  dart.setSignature(parameter_initializer2_test.F, {
    constructors: () => ({
      new: dart.definiteFunctionType(parameter_initializer2_test.F, [dart.dynamic, core.int, core.int, core.int]),
      foobar: dart.definiteFunctionType(parameter_initializer2_test.F, [core.int, core.int, core.int])
    })
  });
  parameter_initializer2_test.main = function() {
    parameter_initializer2_test.ParameterInitializer2Test.testMain();
  };
  dart.fn(parameter_initializer2_test.main, VoidTodynamic());
  // Exports:
  exports.parameter_initializer2_test = parameter_initializer2_test;
});
