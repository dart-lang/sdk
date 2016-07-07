dart_library.library('language/type_promotion_multiple_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__type_promotion_multiple_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_promotion_multiple_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let ATovoid = () => (ATovoid = dart.constFn(dart.definiteFunctionType(dart.void, [type_promotion_multiple_test_none_multi.A])))();
  type_promotion_multiple_test_none_multi.A = class A extends core.Object {
    new() {
      this.a = "a";
    }
  };
  type_promotion_multiple_test_none_multi.B = class B extends type_promotion_multiple_test_none_multi.A {
    new() {
      this.b = "b";
      super.new();
    }
  };
  type_promotion_multiple_test_none_multi.C = class C extends type_promotion_multiple_test_none_multi.B {
    new() {
      this.c = "c";
      super.new();
    }
  };
  type_promotion_multiple_test_none_multi.D = class D extends type_promotion_multiple_test_none_multi.A {
    new() {
      this.d = "d";
      super.new();
    }
  };
  type_promotion_multiple_test_none_multi.E = class E extends core.Object {
    new() {
      this.a = "";
      this.b = "";
      this.c = "";
      this.d = "";
    }
  };
  type_promotion_multiple_test_none_multi.E[dart.implements] = () => [type_promotion_multiple_test_none_multi.C, type_promotion_multiple_test_none_multi.D];
  type_promotion_multiple_test_none_multi.main = function() {
    type_promotion_multiple_test_none_multi.test(new type_promotion_multiple_test_none_multi.E());
  };
  dart.fn(type_promotion_multiple_test_none_multi.main, VoidTovoid());
  type_promotion_multiple_test_none_multi.test = function(a1) {
    let a2 = new type_promotion_multiple_test_none_multi.E();
    core.print(a1.a);
    core.print(a2.a);
    if (type_promotion_multiple_test_none_multi.B.is(a1) && type_promotion_multiple_test_none_multi.C.is(a2)) {
      core.print(a1.a);
      core.print(a1.b);
      core.print(a2.a);
      core.print(a2.b);
      core.print(a2.c);
      if (type_promotion_multiple_test_none_multi.C.is(a1) && type_promotion_multiple_test_none_multi.D.is(a2)) {
        core.print(a1.a);
        core.print(a1.b);
        core.print(a1.c);
        core.print(a2.a);
        core.print(a2.b);
        core.print(a2.c);
      }
    }
    let o1 = type_promotion_multiple_test_none_multi.B.is(a1) && type_promotion_multiple_test_none_multi.C.is(a2) ? dart.str`${a1.a}` + dart.str`${a1.b}` + dart.str`${a2.a}` + dart.str`${a2.b}` + dart.str`${a2.c}` : dart.str`${a1.a}` + dart.str`${a2.a}`;
    if (type_promotion_multiple_test_none_multi.C.is(a2) && type_promotion_multiple_test_none_multi.B.is(a1) && type_promotion_multiple_test_none_multi.C.is(a1) && type_promotion_multiple_test_none_multi.B.is(a2) && type_promotion_multiple_test_none_multi.D.is(a2)) {
      core.print(a1.a);
      core.print(a1.b);
      core.print(a1.c);
      core.print(a2.a);
      core.print(a2.b);
      core.print(a2.c);
    }
  };
  dart.fn(type_promotion_multiple_test_none_multi.test, ATovoid());
  // Exports:
  exports.type_promotion_multiple_test_none_multi = type_promotion_multiple_test_none_multi;
});
