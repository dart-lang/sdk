dart_library.library('language/type_promotion_more_specific_test_08_multi', null, /* Imports */[
  'dart_sdk'
], function load__type_promotion_more_specific_test_08_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_promotion_more_specific_test_08_multi = Object.create(null);
  let D = () => (D = dart.constFn(type_promotion_more_specific_test_08_multi.D$()))();
  let E = () => (E = dart.constFn(type_promotion_more_specific_test_08_multi.E$()))();
  let EOfB = () => (EOfB = dart.constFn(type_promotion_more_specific_test_08_multi.E$(type_promotion_more_specific_test_08_multi.B)))();
  let EOfA = () => (EOfA = dart.constFn(type_promotion_more_specific_test_08_multi.E$(type_promotion_more_specific_test_08_multi.A)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_promotion_more_specific_test_08_multi.A = class A extends core.Object {
    new() {
      this.a = null;
    }
  };
  type_promotion_more_specific_test_08_multi.B = class B extends type_promotion_more_specific_test_08_multi.A {
    new() {
      this.b = null;
      super.new();
    }
  };
  type_promotion_more_specific_test_08_multi.C = class C extends core.Object {
    new() {
      this.c = null;
    }
  };
  type_promotion_more_specific_test_08_multi.D$ = dart.generic(T => {
    class D extends core.Object {
      new(d) {
        this.d = d;
      }
    }
    dart.addTypeTests(D);
    dart.setSignature(D, {
      constructors: () => ({new: dart.definiteFunctionType(type_promotion_more_specific_test_08_multi.D$(T), [T])})
    });
    return D;
  });
  type_promotion_more_specific_test_08_multi.D = D();
  type_promotion_more_specific_test_08_multi.E$ = dart.generic(T => {
    class E extends type_promotion_more_specific_test_08_multi.D$(T) {
      new(e) {
        this.e = T._check(e);
        super.new(T._check(e));
      }
    }
    dart.setSignature(E, {
      constructors: () => ({new: dart.definiteFunctionType(type_promotion_more_specific_test_08_multi.E$(T), [dart.dynamic])})
    });
    return E;
  });
  type_promotion_more_specific_test_08_multi.E = E();
  type_promotion_more_specific_test_08_multi.main = function() {
    type_promotion_more_specific_test_08_multi.testInterface();
    type_promotion_more_specific_test_08_multi.testGeneric();
  };
  dart.fn(type_promotion_more_specific_test_08_multi.main, VoidTovoid());
  type_promotion_more_specific_test_08_multi.testInterface = function() {
    let x = null;
    let y = null;
    let a = new type_promotion_more_specific_test_08_multi.B();
    if (type_promotion_more_specific_test_08_multi.B.is(a)) {
    }
    if (type_promotion_more_specific_test_08_multi.C.is(a)) {
    }
    let b = new type_promotion_more_specific_test_08_multi.B();
    if (type_promotion_more_specific_test_08_multi.A.is(b)) {
    }
    if (type_promotion_more_specific_test_08_multi.A.is(x)) {
    }
  };
  dart.fn(type_promotion_more_specific_test_08_multi.testInterface, VoidTovoid());
  type_promotion_more_specific_test_08_multi.testGeneric = function() {
    let x = null;
    let y = null;
    let d1 = new (EOfB())(null);
    if (type_promotion_more_specific_test_08_multi.E.is(d1)) {
    }
    if (EOfA().is(d1)) {
      x = d1.e;
    }
    let d2 = new (EOfB())(null);
    if (type_promotion_more_specific_test_08_multi.E.is(d2)) {
    }
    let d3 = new (EOfB())(new type_promotion_more_specific_test_08_multi.B());
    if (EOfB().is(d3)) {
    }
  };
  dart.fn(type_promotion_more_specific_test_08_multi.testGeneric, VoidTodynamic());
  // Exports:
  exports.type_promotion_more_specific_test_08_multi = type_promotion_more_specific_test_08_multi;
});
