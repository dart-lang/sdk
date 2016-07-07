dart_library.library('language/optimized_setter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__optimized_setter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const optimized_setter_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamicAndboolTodynamic = () => (dynamicAnddynamicAndboolTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, core.bool])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  optimized_setter_test.A = class A extends core.Object {
    new() {
      this.field = 0;
    }
  };
  optimized_setter_test.B = class B extends optimized_setter_test.A {
    new() {
      super.new();
    }
  };
  optimized_setter_test.sameImplicitSetter = function() {
    function oneTarget(a, v) {
      dart.dput(a, 'field', v);
    }
    dart.fn(oneTarget, dynamicAnddynamicTodynamic());
    let a = new optimized_setter_test.A();
    let b = new optimized_setter_test.B();
    for (let i = 0; i < 20; i++) {
      oneTarget(a, 5);
      expect$.Expect.equals(5, a.field);
    }
    oneTarget(b, 6);
    expect$.Expect.equals(6, b.field);
    for (let i = 0; i < 20; i++) {
      oneTarget(a, 7);
      expect$.Expect.equals(7, a.field);
    }
    oneTarget(b, 8);
    expect$.Expect.equals(8, b.field);
  };
  dart.fn(optimized_setter_test.sameImplicitSetter, VoidTovoid());
  optimized_setter_test.setterNoFeedback = function() {
    function maybeSet(a, v, set_it) {
      if (dart.test(set_it)) {
        return dart.dput(a, 'field', v);
      }
      return -1;
    }
    dart.fn(maybeSet, dynamicAnddynamicAndboolTodynamic());
    let a = new optimized_setter_test.A();
    for (let i = 0; i < 20; i++) {
      let r = maybeSet(a, 5, false);
      expect$.Expect.equals(0, a.field);
      expect$.Expect.equals(-1, r);
    }
    let r = maybeSet(a, 5, true);
    expect$.Expect.equals(5, a.field);
    expect$.Expect.equals(5, r);
    for (let i = 0; i < 20; i++) {
      let r = maybeSet(a, 6, true);
      expect$.Expect.equals(6, a.field);
      expect$.Expect.equals(6, r);
    }
  };
  dart.fn(optimized_setter_test.setterNoFeedback, VoidTovoid());
  optimized_setter_test.X = class X extends core.Object {
    new() {
      this.pField = 0;
    }
    set field(v) {
      this.pField = core.int._check(v);
    }
    get field() {
      return 10;
    }
  };
  optimized_setter_test.sameNotImplicitSetter = function() {
    function oneTarget(a, v) {
      return dart.dput(a, 'field', v);
    }
    dart.fn(oneTarget, dynamicAnddynamicTodynamic());
    function incField(a) {
      dart.dput(a, 'field', dart.dsend(dart.dload(a, 'field'), '+', 1));
    }
    dart.fn(incField, dynamicTodynamic());
    let x = new optimized_setter_test.X();
    for (let i = 0; i < 20; i++) {
      let r = oneTarget(x, 3);
      expect$.Expect.equals(3, x.pField);
      expect$.Expect.equals(3, r);
    }
    oneTarget(x, 0);
    for (let i = 0; i < 20; i++) {
      incField(x);
    }
    expect$.Expect.equals(11, x.pField);
  };
  dart.fn(optimized_setter_test.sameNotImplicitSetter, VoidTovoid());
  optimized_setter_test.Y = class Y extends core.Object {
    new() {
      this.field = 0;
    }
  };
  optimized_setter_test.multiImplicitSetter = function() {
    function oneTarget(a, v) {
      return dart.dput(a, 'field', v);
    }
    dart.fn(oneTarget, dynamicAnddynamicTodynamic());
    let a = new optimized_setter_test.A();
    let y = new optimized_setter_test.Y();
    for (let i = 0; i < 20; i++) {
      let r = oneTarget(a, 5);
      expect$.Expect.equals(5, a.field);
      expect$.Expect.equals(5, r);
      r = oneTarget(y, 6);
      expect$.Expect.equals(6, y.field);
      expect$.Expect.equals(6, r);
    }
  };
  dart.fn(optimized_setter_test.multiImplicitSetter, VoidTodynamic());
  optimized_setter_test.Z = class Z extends core.Object {
    new() {
      this.pField = 0;
    }
    set field(v) {
      this.pField = core.int._check(v);
    }
    get field() {
      return 10;
    }
  };
  optimized_setter_test.multiNotImplicitSetter = function() {
    function oneTarget(a, v) {
      return dart.dput(a, 'field', v);
    }
    dart.fn(oneTarget, dynamicAnddynamicTodynamic());
    let y = new optimized_setter_test.Y();
    let z = new optimized_setter_test.Z();
    for (let i = 0; i < 20; i++) {
      let r = oneTarget(y, 8);
      expect$.Expect.equals(8, y.field);
      expect$.Expect.equals(8, r);
      r = oneTarget(z, 12);
      expect$.Expect.equals(12, z.pField);
      expect$.Expect.equals(12, r);
    }
    let a = new optimized_setter_test.A();
    let r = oneTarget(a, 11);
    expect$.Expect.equals(11, a.field);
    expect$.Expect.equals(11, r);
  };
  dart.fn(optimized_setter_test.multiNotImplicitSetter, VoidTodynamic());
  optimized_setter_test.main = function() {
    optimized_setter_test.sameImplicitSetter();
    optimized_setter_test.setterNoFeedback();
    optimized_setter_test.sameNotImplicitSetter();
    optimized_setter_test.multiImplicitSetter();
    optimized_setter_test.multiNotImplicitSetter();
  };
  dart.fn(optimized_setter_test.main, VoidTovoid());
  // Exports:
  exports.optimized_setter_test = optimized_setter_test;
});
