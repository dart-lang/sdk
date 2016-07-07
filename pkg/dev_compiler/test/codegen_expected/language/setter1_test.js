dart_library.library('language/setter1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setter1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setter1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  setter1_test.First = class First extends core.Object {
    new(val) {
      this.a_ = val;
    }
    testMethod() {
      this.a = 20;
    }
    static testStaticMethod() {
      setter1_test.First.b = 20;
    }
    get a() {
      return this.a_;
    }
    set a(val) {
      this.a_ = dart.notNull(this.a_) + dart.notNull(val);
    }
    static get b() {
      return setter1_test.First.b_;
    }
    static set b(val) {
      setter1_test.First.b_ = val;
    }
  };
  dart.setSignature(setter1_test.First, {
    constructors: () => ({new: dart.definiteFunctionType(setter1_test.First, [core.int])}),
    methods: () => ({testMethod: dart.definiteFunctionType(dart.void, [])}),
    statics: () => ({testStaticMethod: dart.definiteFunctionType(dart.void, [])}),
    names: ['testStaticMethod']
  });
  setter1_test.First.b_ = null;
  setter1_test.Second = class Second extends core.Object {
    new(value) {
      this.a_ = value;
    }
    testMethod() {
      this.a = 20;
    }
    static testStaticMethod() {
      let i = null;
      setter1_test.Second.b = 20;
      i = setter1_test.Second.d;
    }
    get a() {
      return this.a_;
    }
    set a(value) {
      this.a_ = dart.notNull(this.a_) + dart.notNull(value);
    }
    static set b(value) {
      setter1_test.Second.c = value;
    }
    static get d() {
      return setter1_test.Second.c;
    }
  };
  dart.setSignature(setter1_test.Second, {
    constructors: () => ({new: dart.definiteFunctionType(setter1_test.Second, [core.int])}),
    methods: () => ({testMethod: dart.definiteFunctionType(dart.void, [])}),
    statics: () => ({testStaticMethod: dart.definiteFunctionType(dart.void, [])}),
    names: ['testStaticMethod']
  });
  setter1_test.Second.c = null;
  setter1_test.Setter1Test = class Setter1Test extends core.Object {
    static testMain() {
      let obj1 = new setter1_test.First(10);
      expect$.Expect.equals(10, obj1.a);
      obj1.testMethod();
      expect$.Expect.equals(30, obj1.a);
      setter1_test.First.b = 10;
      expect$.Expect.equals(10, setter1_test.First.b);
      setter1_test.First.testStaticMethod();
      expect$.Expect.equals(20, setter1_test.First.b);
      let obj = new setter1_test.Second(10);
      expect$.Expect.equals(10, obj.a);
      obj.testMethod();
      expect$.Expect.equals(30, obj.a);
      setter1_test.Second.testStaticMethod();
      expect$.Expect.equals(20, setter1_test.Second.c);
      expect$.Expect.equals(20, setter1_test.Second.d);
    }
  };
  dart.setSignature(setter1_test.Setter1Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  setter1_test.main = function() {
    setter1_test.Setter1Test.testMain();
  };
  dart.fn(setter1_test.main, VoidTodynamic());
  // Exports:
  exports.setter1_test = setter1_test;
});
