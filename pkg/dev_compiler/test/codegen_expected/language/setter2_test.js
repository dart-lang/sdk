dart_library.library('language/setter2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setter2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setter2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  setter2_test.Nested = class Nested extends core.Object {
    new(val) {
      this.a = val;
    }
    foo(i) {
      return i;
    }
  };
  dart.setSignature(setter2_test.Nested, {
    constructors: () => ({new: dart.definiteFunctionType(setter2_test.Nested, [core.int])}),
    methods: () => ({foo: dart.definiteFunctionType(core.int, [core.int])})
  });
  setter2_test.Second = class Second extends core.Object {
    new(val) {
      this.a = null;
    }
    bar(value) {
      this.a = value;
      setter2_test.Second.obj.a = setter2_test.Second.obj.foo(this.a);
      this.a = 100;
      expect$.Expect.equals(100, this.a);
    }
  };
  dart.setSignature(setter2_test.Second, {
    constructors: () => ({new: dart.definiteFunctionType(setter2_test.Second, [core.int])}),
    methods: () => ({bar: dart.definiteFunctionType(dart.void, [core.int])})
  });
  setter2_test.Second.obj = null;
  setter2_test.Setter2Test = class Setter2Test extends core.Object {
    static testMain() {
      let obj = new setter2_test.Second(10);
      setter2_test.Second.obj = new setter2_test.Nested(10);
      setter2_test.Second.obj.a = 10;
      expect$.Expect.equals(10, setter2_test.Second.obj.a);
      expect$.Expect.equals(10, setter2_test.Second.obj.foo(10));
      obj.bar(20);
      expect$.Expect.equals(20, setter2_test.Second.obj.a);
    }
  };
  dart.setSignature(setter2_test.Setter2Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  setter2_test.main = function() {
    setter2_test.Setter2Test.testMain();
  };
  dart.fn(setter2_test.main, VoidTodynamic());
  // Exports:
  exports.setter2_test = setter2_test;
});
