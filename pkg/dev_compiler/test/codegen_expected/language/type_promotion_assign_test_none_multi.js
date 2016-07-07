dart_library.library('language/type_promotion_assign_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__type_promotion_assign_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_promotion_assign_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  type_promotion_assign_test_none_multi.A = class A extends core.Object {
    new() {
      this.a = "a";
    }
  };
  type_promotion_assign_test_none_multi.B = class B extends type_promotion_assign_test_none_multi.A {
    new() {
      this.b = "b";
      super.new();
    }
  };
  type_promotion_assign_test_none_multi.C = class C extends type_promotion_assign_test_none_multi.B {
    new() {
      this.c = "c";
      super.new();
    }
  };
  type_promotion_assign_test_none_multi.D = class D extends type_promotion_assign_test_none_multi.A {
    new() {
      this.d = "d";
      super.new();
    }
  };
  type_promotion_assign_test_none_multi.E = class E extends core.Object {
    new() {
      this.a = "";
      this.b = "";
      this.c = "";
      this.d = "";
    }
  };
  type_promotion_assign_test_none_multi.E[dart.implements] = () => [type_promotion_assign_test_none_multi.C, type_promotion_assign_test_none_multi.D];
  type_promotion_assign_test_none_multi.main = function() {
    let a = new type_promotion_assign_test_none_multi.E();
    if (type_promotion_assign_test_none_multi.B.is(a)) {
      core.print(a.a);
      a = null;
    }
    if (type_promotion_assign_test_none_multi.B.is(a)) {
      a = null;
      core.print(a.a);
    }
    if (type_promotion_assign_test_none_multi.B.is(a)) {
      core.print(a.a);
      {
        a = null;
      }
      core.print(a.a);
    }
  };
  dart.fn(type_promotion_assign_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.type_promotion_assign_test_none_multi = type_promotion_assign_test_none_multi;
});
