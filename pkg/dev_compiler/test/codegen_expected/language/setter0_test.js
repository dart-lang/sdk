dart_library.library('language/setter0_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setter0_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setter0_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  setter0_test.First = class First extends core.Object {
    new(val) {
      this.a_ = val;
    }
  };
  dart.setSignature(setter0_test.First, {
    constructors: () => ({new: dart.definiteFunctionType(setter0_test.First, [core.int])})
  });
  setter0_test.Second = class Second extends setter0_test.First {
    new(val) {
      super.new(val);
    }
    static testStaticMethod() {
      let i = null;
      setter0_test.Second.static_a = 20;
      i = setter0_test.Second.c;
    }
    set instance_a(value) {
      this.a_ = dart.notNull(this.a_) + dart.notNull(value);
    }
    get instance_a() {
      return this.a_;
    }
    static set static_a(value) {
      setter0_test.Second.c = value;
    }
    static get static_d() {
      return setter0_test.Second.c;
    }
  };
  dart.setSignature(setter0_test.Second, {
    constructors: () => ({new: dart.definiteFunctionType(setter0_test.Second, [core.int])}),
    statics: () => ({testStaticMethod: dart.definiteFunctionType(dart.void, [])}),
    names: ['testStaticMethod']
  });
  setter0_test.Second.c = null;
  setter0_test.Setter0Test = class Setter0Test extends core.Object {
    static testMain() {
      let obj = new setter0_test.Second(10);
      expect$.Expect.equals(10, obj.instance_a);
      obj.instance_a = 20;
      expect$.Expect.equals(30, obj.instance_a);
      setter0_test.Second.testStaticMethod();
      expect$.Expect.equals(20, setter0_test.Second.c);
      expect$.Expect.equals(20, setter0_test.Second.static_d);
    }
  };
  dart.setSignature(setter0_test.Setter0Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  setter0_test.main = function() {
    setter0_test.Setter0Test.testMain();
  };
  dart.fn(setter0_test.main, VoidTodynamic());
  // Exports:
  exports.setter0_test = setter0_test;
});
