dart_library.library('language/getters_setters2_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__getters_setters2_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const getters_setters2_test_01_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  getters_setters2_test_01_multi.A = class A extends core.Object {
    a() {
      return 37;
    }
  };
  dart.setSignature(getters_setters2_test_01_multi.A, {
    methods: () => ({a: dart.definiteFunctionType(core.int, [])})
  });
  getters_setters2_test_01_multi.B = class B extends getters_setters2_test_01_multi.A {
    b() {
      return 38;
    }
  };
  dart.setSignature(getters_setters2_test_01_multi.B, {
    methods: () => ({b: dart.definiteFunctionType(core.int, [])})
  });
  getters_setters2_test_01_multi.C = class C extends core.Object {};
  getters_setters2_test_01_multi.T1 = class T1 extends core.Object {
    new() {
      this.getterField = null;
    }
    get field() {
      return this.getterField;
    }
    set field(arg) {
      this.getterField = arg;
    }
  };
  getters_setters2_test_01_multi.T2 = class T2 extends core.Object {
    new() {
      this.getterField = null;
      this.setterField = null;
    }
    get field() {
      return this.getterField;
    }
    set field(arg) {
      this.setterField = arg;
    }
  };
  getters_setters2_test_01_multi.T3 = class T3 extends core.Object {
    new() {
      this.getterField = null;
    }
    get field() {
      return this.getterField;
    }
    set field(arg) {
      this.getterField = getters_setters2_test_01_multi.B._check(arg);
    }
  };
  getters_setters2_test_01_multi.main = function() {
    let instance1 = new getters_setters2_test_01_multi.T1();
    let instance2 = new getters_setters2_test_01_multi.T2();
    let instance3 = new getters_setters2_test_01_multi.T3();
    instance1.field = new getters_setters2_test_01_multi.B();
    let resultA = instance1.field;
    let resultB = getters_setters2_test_01_multi.B._check(instance1.field);
    let result = null;
    result = instance1.field.a();
    expect$.Expect.equals(37, result);
    instance3.field = new getters_setters2_test_01_multi.B();
    result = instance3.field.a();
    expect$.Expect.equals(37, result);
    result = instance3.field.b();
    expect$.Expect.equals(38, result);
  };
  dart.fn(getters_setters2_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.getters_setters2_test_01_multi = getters_setters2_test_01_multi;
});
