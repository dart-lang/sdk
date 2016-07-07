dart_library.library('language/method_binding_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__method_binding_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const method_binding_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  method_binding_test.A = class A extends core.Object {
    new(a) {
      this.a = a;
    }
    static foo() {
      return 4;
    }
    bar() {
      return this.a;
    }
    baz() {
      return this.a;
    }
    getThis() {
      return dart.bind(this, 'bar');
    }
    getNoThis() {
      return dart.bind(this, 'bar');
    }
    methodArgs(arg) {
      return dart.dsend(arg, '+', this.a);
    }
    selfReference() {
      return dart.bind(this, 'selfReference');
    }
    invokeBaz() {
      return dart.bind(this, 'baz')();
    }
    invokeBar(obj) {
      return dart.dcall(dart.dload(obj, 'bar'));
    }
    invokeThisBar() {
      return dart.bind(this, 'bar')();
    }
    implicitStaticRef() {
      return method_binding_test.A.foo;
    }
  };
  dart.setSignature(method_binding_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(method_binding_test.A, [core.int])}),
    methods: () => ({
      bar: dart.definiteFunctionType(dart.dynamic, []),
      baz: dart.definiteFunctionType(core.int, []),
      getThis: dart.definiteFunctionType(dart.dynamic, []),
      getNoThis: dart.definiteFunctionType(dart.dynamic, []),
      methodArgs: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      selfReference: dart.definiteFunctionType(dart.dynamic, []),
      invokeBaz: dart.definiteFunctionType(dart.dynamic, []),
      invokeBar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      invokeThisBar: dart.definiteFunctionType(dart.dynamic, []),
      implicitStaticRef: dart.definiteFunctionType(dart.dynamic, [])
    }),
    statics: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['foo']
  });
  method_binding_test.A.func = null;
  method_binding_test.B = class B extends core.Object {
    static foo() {
      return -1;
    }
  };
  dart.setSignature(method_binding_test.B, {
    statics: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['foo']
  });
  method_binding_test.C = class C extends core.Object {
    new() {
      this.f = null;
    }
  };
  dart.setSignature(method_binding_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(method_binding_test.C, [])})
  });
  method_binding_test.topLevel99 = function() {
    return 99;
  };
  dart.fn(method_binding_test.topLevel99, VoidTodynamic());
  method_binding_test.topFunc = null;
  method_binding_test.D = class D extends method_binding_test.A {
    new(a) {
      super.new(core.int._check(a));
    }
    getSuper() {
      return dart.bind(this, 'bar', super.bar);
    }
  };
  dart.setSignature(method_binding_test.D, {
    constructors: () => ({new: dart.definiteFunctionType(method_binding_test.D, [dart.dynamic])}),
    methods: () => ({getSuper: dart.definiteFunctionType(dart.dynamic, [])})
  });
  method_binding_test.MethodBindingTest = class MethodBindingTest extends core.Object {
    static test() {
      expect$.Expect.equals(99, method_binding_test.topLevel99());
      let f99 = method_binding_test.topLevel99;
      expect$.Expect.equals(99, dart.dcall(f99));
      method_binding_test.topFunc = f99;
      expect$.Expect.equals(99, dart.dcall(method_binding_test.topFunc));
      let f4 = method_binding_test.A.foo;
      expect$.Expect.equals(4, dart.dcall(f4));
      let o5 = new method_binding_test.A(5);
      let f5 = dart.bind(o5, 'bar');
      expect$.Expect.equals(5, dart.dcall(f5));
      let c = new method_binding_test.C();
      c.f = dart.fn(() => "success", VoidToString());
      expect$.Expect.equals("success", dart.dsend(c, 'f'));
      let o6 = new method_binding_test.A(6);
      let f6 = o6.getThis();
      expect$.Expect.equals(6, dart.dcall(f6));
      let o7 = new method_binding_test.A(7);
      let f7 = o7.getNoThis();
      expect$.Expect.equals(7, dart.dcall(f7));
      let o8 = new method_binding_test.A(8);
      let f8 = dart.bind(o8, 'methodArgs');
      expect$.Expect.equals(9, dart.dcall(f8, 1));
      let o9 = new method_binding_test.A(9);
      let f9 = dart.bind(o9, 'selfReference');
      let o10 = new method_binding_test.A(10);
      expect$.Expect.equals(10, o10.invokeBaz());
      let o11 = new method_binding_test.A(11);
      expect$.Expect.equals(10, o11.invokeBar(o10));
      let o12 = new method_binding_test.A(12);
      expect$.Expect.equals(12, o12.invokeThisBar());
      let o13 = new method_binding_test.A(13);
      let f13 = core.Function._check(o13.implicitStaticRef());
      expect$.Expect.equals(4, dart.dcall(f13));
      let o14 = new method_binding_test.D(14);
      let f14 = core.Function._check(o14.getSuper());
      expect$.Expect.equals(14, dart.dcall(f14));
      method_binding_test.A.func = method_binding_test.A.foo;
      expect$.Expect.equals(4, dart.dsend(method_binding_test.A, 'func'));
      let o15 = 'hithere';
      let f15 = dart.bind(o15, dartx.substring);
      expect$.Expect.equals('i', f15(1, 2));
      let o16 = 'hithere';
      let f16 = dart.bind(o16, dartx.substring);
      expect$.Expect.equals('i', f16(1, 2));
      let f17 = dart.bind('hithere', dartx.substring);
      expect$.Expect.equals('i', f17(1, 2));
    }
    static testMain() {
      method_binding_test.MethodBindingTest.test();
    }
  };
  dart.setSignature(method_binding_test.MethodBindingTest, {
    statics: () => ({
      test: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['test', 'testMain']
  });
  method_binding_test.main = function() {
    method_binding_test.MethodBindingTest.testMain();
  };
  dart.fn(method_binding_test.main, VoidTodynamic());
  // Exports:
  exports.method_binding_test = method_binding_test;
});
