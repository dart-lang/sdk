dart_library.library('language/type_promotion_logical_and_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__type_promotion_logical_and_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_promotion_logical_and_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  type_promotion_logical_and_test_none_multi.A = class A extends core.Object {
    new() {
      this.a = true;
    }
  };
  type_promotion_logical_and_test_none_multi.B = class B extends type_promotion_logical_and_test_none_multi.A {
    new() {
      this.b = true;
      super.new();
    }
  };
  type_promotion_logical_and_test_none_multi.C = class C extends type_promotion_logical_and_test_none_multi.B {
    new() {
      this.c = true;
      super.new();
    }
  };
  type_promotion_logical_and_test_none_multi.D = class D extends type_promotion_logical_and_test_none_multi.A {
    new() {
      this.d = true;
      super.new();
    }
  };
  type_promotion_logical_and_test_none_multi.E = class E extends core.Object {
    new() {
      this.a = true;
      this.b = true;
      this.c = true;
      this.d = true;
    }
  };
  type_promotion_logical_and_test_none_multi.E[dart.implements] = () => [type_promotion_logical_and_test_none_multi.C, type_promotion_logical_and_test_none_multi.D];
  type_promotion_logical_and_test_none_multi.main = function() {
    let a = new type_promotion_logical_and_test_none_multi.E();
    let b = null;
    if (type_promotion_logical_and_test_none_multi.D.is(a) && (a = new type_promotion_logical_and_test_none_multi.D()) != null) {
    }
    if (type_promotion_logical_and_test_none_multi.D.is(a) && dart.test(b = a.d)) {
      a = null;
    }
    if (type_promotion_logical_and_test_none_multi.D.is(a) && dart.test(b = a.d)) {
      a = null;
    }
    if (dart.test(type_promotion_logical_and_test_none_multi.f(a = null)) && type_promotion_logical_and_test_none_multi.D.is(a)) {
      b = a.d;
    }
  };
  dart.fn(type_promotion_logical_and_test_none_multi.main, VoidTovoid());
  type_promotion_logical_and_test_none_multi.f = function(x) {
    return true;
  };
  dart.fn(type_promotion_logical_and_test_none_multi.f, dynamicTobool());
  // Exports:
  exports.type_promotion_logical_and_test_none_multi = type_promotion_logical_and_test_none_multi;
});
