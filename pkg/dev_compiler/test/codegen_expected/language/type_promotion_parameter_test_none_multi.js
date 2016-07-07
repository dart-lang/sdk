dart_library.library('language/type_promotion_parameter_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__type_promotion_parameter_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_promotion_parameter_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let ATovoid = () => (ATovoid = dart.constFn(dart.definiteFunctionType(dart.void, [type_promotion_parameter_test_none_multi.A])))();
  type_promotion_parameter_test_none_multi.A = class A extends core.Object {
    new() {
      this.a = "a";
    }
  };
  type_promotion_parameter_test_none_multi.B = class B extends type_promotion_parameter_test_none_multi.A {
    new() {
      this.b = "b";
      super.new();
    }
  };
  type_promotion_parameter_test_none_multi.C = class C extends type_promotion_parameter_test_none_multi.B {
    new() {
      this.c = "c";
      super.new();
    }
  };
  type_promotion_parameter_test_none_multi.D = class D extends type_promotion_parameter_test_none_multi.A {
    new() {
      this.d = "d";
      super.new();
    }
  };
  type_promotion_parameter_test_none_multi.E = class E extends core.Object {
    new() {
      this.a = "";
      this.b = "";
      this.c = "";
      this.d = "";
    }
  };
  type_promotion_parameter_test_none_multi.E[dart.implements] = () => [type_promotion_parameter_test_none_multi.C, type_promotion_parameter_test_none_multi.D];
  type_promotion_parameter_test_none_multi.main = function() {
    type_promotion_parameter_test_none_multi.test(new type_promotion_parameter_test_none_multi.E());
  };
  dart.fn(type_promotion_parameter_test_none_multi.main, VoidTovoid());
  type_promotion_parameter_test_none_multi.test = function(a) {
    core.print(a.a);
    if (type_promotion_parameter_test_none_multi.B.is(a)) {
      core.print(a.a);
      core.print(a.b);
      if (type_promotion_parameter_test_none_multi.C.is(a)) {
        core.print(a.a);
        core.print(a.b);
        core.print(a.c);
      }
      core.print(a.a);
      core.print(a.b);
    }
    if (type_promotion_parameter_test_none_multi.C.is(a)) {
      core.print(a.a);
      core.print(a.b);
      core.print(a.c);
      if (type_promotion_parameter_test_none_multi.B.is(a)) {
        core.print(a.a);
        core.print(a.b);
        core.print(a.c);
      }
      if (type_promotion_parameter_test_none_multi.D.is(a)) {
        core.print(a.a);
        core.print(a.b);
        core.print(a.c);
      }
      core.print(a.a);
      core.print(a.b);
      core.print(a.c);
    }
    core.print(a.a);
    if (type_promotion_parameter_test_none_multi.D.is(a)) {
      core.print(a.a);
      core.print(a.d);
    }
    core.print(a.a);
    let o1 = type_promotion_parameter_test_none_multi.B.is(a) ? dart.str`${a.a}` + dart.str`${a.b}` : dart.str`${a.a}`;
    let o2 = type_promotion_parameter_test_none_multi.C.is(a) ? dart.str`${a.a}` + dart.str`${a.b}` + dart.str`${a.c}` : dart.str`${a.a}`;
    let o3 = type_promotion_parameter_test_none_multi.D.is(a) ? dart.str`${a.a}` + dart.str`${a.d}` : dart.str`${a.a}`;
    if (type_promotion_parameter_test_none_multi.B.is(a) && type_promotion_parameter_test_none_multi.B.is(a)) {
      core.print(a.a);
      core.print(a.b);
    }
    if (type_promotion_parameter_test_none_multi.B.is(a) && type_promotion_parameter_test_none_multi.C.is(a)) {
      core.print(a.a);
      core.print(a.b);
      core.print(a.c);
    }
    if (type_promotion_parameter_test_none_multi.C.is(a) && type_promotion_parameter_test_none_multi.B.is(a)) {
      core.print(a.a);
      core.print(a.b);
      core.print(a.c);
    }
    if (type_promotion_parameter_test_none_multi.C.is(a) && type_promotion_parameter_test_none_multi.D.is(a)) {
      core.print(a.a);
      core.print(a.b);
      core.print(a.c);
    }
    if (type_promotion_parameter_test_none_multi.D.is(a) && type_promotion_parameter_test_none_multi.C.is(a)) {
      core.print(a.a);
      core.print(a.d);
    }
    if (type_promotion_parameter_test_none_multi.D.is(a) && a.a == "" && a.d == "") {
      core.print(a.a);
      core.print(a.d);
    }
    if (a.a == "" && type_promotion_parameter_test_none_multi.B.is(a) && a.a == "" && a.b == "" && type_promotion_parameter_test_none_multi.C.is(a) && a.a == "" && a.b == "" && a.c == "") {
      core.print(a.a);
      core.print(a.b);
      core.print(a.c);
    }
    if (type_promotion_parameter_test_none_multi.B.is(a)) {
      core.print(a.a);
      core.print(a.b);
    }
    if (type_promotion_parameter_test_none_multi.B.is(a) && type_promotion_parameter_test_none_multi.C.is(a) && type_promotion_parameter_test_none_multi.B.is(a)) {
      core.print(a.a);
      core.print(a.b);
      core.print(a.c);
    }
  };
  dart.fn(type_promotion_parameter_test_none_multi.test, ATovoid());
  // Exports:
  exports.type_promotion_parameter_test_none_multi = type_promotion_parameter_test_none_multi;
});
