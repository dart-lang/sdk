dart_library.library('language/class_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__class_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const class_test = Object.create(null);
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  class_test.ClassTest = class ClassTest extends core.Object {
    new() {
    }
    static testMain() {
      let test = new class_test.ClassTest();
      test.testSuperCalls();
      test.testVirtualCalls();
      test.testStaticCalls();
      test.testInheritedField();
      test.testMemberRefInClosure();
      test.testFactory();
      test.testNamedConstructors();
      test.testDefaultImplementation();
      test.testFunctionParameter(dart.fn(a => a, intToint()));
    }
    testFunctionParameter(func) {
      expect$.Expect.equals(1, func(1));
    }
    testSuperCalls() {
      let sub = new class_test.Sub();
      expect$.Expect.equals(43, sub.methodX());
      expect$.Expect.equals(84, sub.methodK());
    }
    testVirtualCalls() {
      let sub = new class_test.Sub();
      expect$.Expect.equals(41, sub.method2());
      expect$.Expect.equals(41, sub.method3());
    }
    testStaticCalls() {
      let sub = new class_test.Sub();
      expect$.Expect.equals(-42, class_test.Sub.method4());
      expect$.Expect.equals(-41, sub.method5());
    }
    testInheritedField() {
      let sub = new class_test.Sub();
      expect$.Expect.equals(42, sub.method6());
    }
    testMemberRefInClosure() {
      let sub = new class_test.Sub();
      expect$.Expect.equals(1, sub.closureRef());
      expect$.Expect.equals(2, sub.closureRef());
      sub = new class_test.Sub();
      expect$.Expect.equals(1, sub.closureRef());
      expect$.Expect.equals(2, sub.closureRef());
    }
    testFactory() {
      let sup = class_test.Sup.named();
      expect$.Expect.equals(43, sup.methodX());
      expect$.Expect.equals(84, sup.methodK());
    }
    testNamedConstructors() {
      let sup = new class_test.Sup.fromInt(4);
      expect$.Expect.equals(4, sup.methodX());
      expect$.Expect.equals(0, sup.methodK());
    }
    testDefaultImplementation() {
      let x = class_test.Inter.new(4);
      expect$.Expect.equals(4, x.methodX());
      expect$.Expect.equals(8, x.methodK());
      x = class_test.Inter.fromInt(4);
      expect$.Expect.equals(4, x.methodX());
      expect$.Expect.equals(0, x.methodK());
      x = class_test.Inter.named();
      expect$.Expect.equals(43, x.methodX());
      expect$.Expect.equals(84, x.methodK());
      x = class_test.Inter.factory();
      expect$.Expect.equals(43, x.methodX());
      expect$.Expect.equals(84, x.methodK());
    }
  };
  dart.setSignature(class_test.ClassTest, {
    constructors: () => ({new: dart.definiteFunctionType(class_test.ClassTest, [])}),
    methods: () => ({
      testFunctionParameter: dart.definiteFunctionType(dart.dynamic, [dart.functionType(core.int, [core.int])]),
      testSuperCalls: dart.definiteFunctionType(dart.dynamic, []),
      testVirtualCalls: dart.definiteFunctionType(dart.dynamic, []),
      testStaticCalls: dart.definiteFunctionType(dart.dynamic, []),
      testInheritedField: dart.definiteFunctionType(dart.dynamic, []),
      testMemberRefInClosure: dart.definiteFunctionType(dart.dynamic, []),
      testFactory: dart.definiteFunctionType(dart.dynamic, []),
      testNamedConstructors: dart.definiteFunctionType(dart.dynamic, []),
      testDefaultImplementation: dart.definiteFunctionType(dart.dynamic, [])
    }),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  class_test.Inter = class Inter extends core.Object {
    static named() {
      return class_test.Sup.named();
    }
    static fromInt(x) {
      return new class_test.Sup.fromInt(x);
    }
    static new(x) {
      return new class_test.Sup(x);
    }
    static factory() {
      return class_test.Sup.factory();
    }
  };
  dart.setSignature(class_test.Inter, {
    constructors: () => ({
      named: dart.definiteFunctionType(class_test.Inter, []),
      fromInt: dart.definiteFunctionType(class_test.Inter, [core.int]),
      new: dart.definiteFunctionType(class_test.Inter, [core.int]),
      factory: dart.definiteFunctionType(class_test.Inter, [])
    })
  });
  class_test.Sup = class Sup extends core.Object {
    static named() {
      return new class_test.Sub();
    }
    static factory() {
      return new class_test.Sub();
    }
    fromInt(x) {
      this.x_ = null;
      this.k_ = null;
      this.x_ = x;
      this.k_ = 0;
    }
    methodX() {
      return this.x_;
    }
    methodK() {
      return this.k_;
    }
    new(x) {
      this.x_ = x;
      this.k_ = null;
      this.k_ = dart.notNull(x) * 2;
    }
    method2() {
      return dart.notNull(this.x_) - 1;
    }
  };
  dart.defineNamedConstructor(class_test.Sup, 'fromInt');
  class_test.Sup[dart.implements] = () => [class_test.Inter];
  dart.setSignature(class_test.Sup, {
    constructors: () => ({
      named: dart.definiteFunctionType(class_test.Sup, []),
      factory: dart.definiteFunctionType(class_test.Sup, []),
      fromInt: dart.definiteFunctionType(class_test.Sup, [core.int]),
      new: dart.definiteFunctionType(class_test.Sup, [core.int])
    }),
    methods: () => ({
      methodX: dart.definiteFunctionType(core.int, []),
      methodK: dart.definiteFunctionType(core.int, []),
      method2: dart.definiteFunctionType(core.int, [])
    })
  });
  class_test.Sub = class Sub extends class_test.Sup {
    methodX() {
      return dart.notNull(super.methodX()) + 1;
    }
    method3() {
      return this.method2();
    }
    static method4() {
      return -42;
    }
    method5() {
      return dart.notNull(class_test.Sub.method4()) + 1;
    }
    method6() {
      return dart.notNull(this.x_) + dart.notNull(this.y_);
    }
    closureRef() {
      let f = dart.fn(() => {
        this.y_ = dart.notNull(this.y_) + 1;
        return this.y_;
      }, VoidToint());
      return f();
    }
    new() {
      this.y_ = null;
      super.new(42);
      this.y_ = 0;
    }
  };
  dart.setSignature(class_test.Sub, {
    constructors: () => ({new: dart.definiteFunctionType(class_test.Sub, [])}),
    methods: () => ({
      method3: dart.definiteFunctionType(core.int, []),
      method5: dart.definiteFunctionType(core.int, []),
      method6: dart.definiteFunctionType(core.int, []),
      closureRef: dart.definiteFunctionType(core.int, [])
    }),
    statics: () => ({method4: dart.definiteFunctionType(core.int, [])}),
    names: ['method4']
  });
  class_test.main = function() {
    class_test.ClassTest.testMain();
  };
  dart.fn(class_test.main, VoidTodynamic());
  // Exports:
  exports.class_test = class_test;
});
