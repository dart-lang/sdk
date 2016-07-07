dart_library.library('language/compile_time_constant10_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant10_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant10_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant10_test_none_multi.C = class C extends core.Object {
    new(x) {
      this.x = x;
    }
    static f3() {}
    static f4() {}
  };
  dart.setSignature(compile_time_constant10_test_none_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant10_test_none_multi.C, [dart.dynamic])}),
    statics: () => ({
      f3: dart.definiteFunctionType(dart.dynamic, []),
      f4: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['f3', 'f4']
  });
  compile_time_constant10_test_none_multi.i1 = 1;
  compile_time_constant10_test_none_multi.i2 = 2;
  compile_time_constant10_test_none_multi.d1 = 1.5;
  compile_time_constant10_test_none_multi.d2 = 2.5;
  compile_time_constant10_test_none_multi.b1 = true;
  compile_time_constant10_test_none_multi.b2 = false;
  compile_time_constant10_test_none_multi.s1 = "1";
  compile_time_constant10_test_none_multi.s2 = "2";
  compile_time_constant10_test_none_multi.l1 = dart.constList([1, 2], core.int);
  compile_time_constant10_test_none_multi.l2 = dart.constList([2, 3], core.int);
  compile_time_constant10_test_none_multi.m1 = dart.const(dart.map({x: 1}));
  compile_time_constant10_test_none_multi.m2 = dart.const(dart.map({x: 2}));
  compile_time_constant10_test_none_multi.c1 = dart.const(new compile_time_constant10_test_none_multi.C(1));
  compile_time_constant10_test_none_multi.c2 = dart.const(new compile_time_constant10_test_none_multi.C(2));
  compile_time_constant10_test_none_multi.f1 = function() {
  };
  dart.fn(compile_time_constant10_test_none_multi.f1, VoidTodynamic());
  compile_time_constant10_test_none_multi.f2 = function() {
  };
  dart.fn(compile_time_constant10_test_none_multi.f2, VoidTodynamic());
  compile_time_constant10_test_none_multi.id = core.identical;
  compile_time_constant10_test_none_multi.CT = class CT extends core.Object {
    new(x1, x2) {
      this.x1 = x1;
      this.x2 = x2;
      this.id = core.identical(x1, x2);
    }
    test(expect, name) {
      dart.dcall(expect, this.id, dart.str`${name}: identical(${this.x1},${this.x2})`);
    }
  };
  dart.setSignature(compile_time_constant10_test_none_multi.CT, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant10_test_none_multi.CT, [dart.dynamic, dart.dynamic])}),
    methods: () => ({test: dart.definiteFunctionType(dart.void, [dart.functionType(dart.void, [dart.dynamic, dart.dynamic]), dart.dynamic])})
  });
  compile_time_constant10_test_none_multi.trueTests = dart.constList([dart.const(new compile_time_constant10_test_none_multi.CT(2 - 1, compile_time_constant10_test_none_multi.i1)), dart.const(new compile_time_constant10_test_none_multi.CT(1 + 1, compile_time_constant10_test_none_multi.i2)), dart.const(new compile_time_constant10_test_none_multi.CT(2.5 - 1.0, compile_time_constant10_test_none_multi.d1)), dart.const(new compile_time_constant10_test_none_multi.CT(1.5 + 1.0, compile_time_constant10_test_none_multi.d2)), dart.const(new compile_time_constant10_test_none_multi.CT(false || true, compile_time_constant10_test_none_multi.b1)), dart.const(new compile_time_constant10_test_none_multi.CT(true && false, compile_time_constant10_test_none_multi.b2)), dart.const(new compile_time_constant10_test_none_multi.CT(dart.str`${compile_time_constant10_test_none_multi.i1}`, compile_time_constant10_test_none_multi.s1)), dart.const(new compile_time_constant10_test_none_multi.CT(dart.str`${compile_time_constant10_test_none_multi.i2}`, compile_time_constant10_test_none_multi.s2)), dart.const(new compile_time_constant10_test_none_multi.CT(dart.constList([compile_time_constant10_test_none_multi.i1, 2], core.int), compile_time_constant10_test_none_multi.l1)), dart.const(new compile_time_constant10_test_none_multi.CT(dart.constList([compile_time_constant10_test_none_multi.i2, 3], core.int), compile_time_constant10_test_none_multi.l2)), dart.const(new compile_time_constant10_test_none_multi.CT(dart.const(dart.map({x: compile_time_constant10_test_none_multi.i1})), compile_time_constant10_test_none_multi.m1)), dart.const(new compile_time_constant10_test_none_multi.CT(dart.const(dart.map({x: compile_time_constant10_test_none_multi.i2})), compile_time_constant10_test_none_multi.m2)), dart.const(new compile_time_constant10_test_none_multi.CT(dart.const(new compile_time_constant10_test_none_multi.C(compile_time_constant10_test_none_multi.i1)), compile_time_constant10_test_none_multi.c1)), dart.const(new compile_time_constant10_test_none_multi.CT(dart.const(new compile_time_constant10_test_none_multi.C(compile_time_constant10_test_none_multi.i2)), compile_time_constant10_test_none_multi.c2)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.f1, compile_time_constant10_test_none_multi.f1)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.f2, compile_time_constant10_test_none_multi.f2)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.C.f3, compile_time_constant10_test_none_multi.C.f3)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.C.f4, compile_time_constant10_test_none_multi.C.f4)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.id, core.identical))], compile_time_constant10_test_none_multi.CT);
  compile_time_constant10_test_none_multi.falseTests = dart.constList([dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.i1, compile_time_constant10_test_none_multi.i2)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.d1, compile_time_constant10_test_none_multi.d2)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.b1, compile_time_constant10_test_none_multi.b2)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.s1, compile_time_constant10_test_none_multi.s2)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.l1, compile_time_constant10_test_none_multi.l2)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.m1, compile_time_constant10_test_none_multi.m2)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.c1, compile_time_constant10_test_none_multi.c2)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.f1, compile_time_constant10_test_none_multi.f2)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.i1, compile_time_constant10_test_none_multi.d1)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.d1, compile_time_constant10_test_none_multi.b1)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.b1, compile_time_constant10_test_none_multi.s1)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.s1, compile_time_constant10_test_none_multi.l1)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.l1, compile_time_constant10_test_none_multi.m1)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.m1, compile_time_constant10_test_none_multi.c1)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.c1, compile_time_constant10_test_none_multi.f1)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.f1, compile_time_constant10_test_none_multi.C.f3)), dart.const(new compile_time_constant10_test_none_multi.CT(compile_time_constant10_test_none_multi.C.f3, core.identical)), dart.const(new compile_time_constant10_test_none_multi.CT(core.identical, compile_time_constant10_test_none_multi.i1))], compile_time_constant10_test_none_multi.CT);
  compile_time_constant10_test_none_multi.main = function() {
    for (let i = 0; i < dart.notNull(compile_time_constant10_test_none_multi.trueTests[dartx.length]); i++) {
      compile_time_constant10_test_none_multi.trueTests[dartx.get](i).test(expect$.Expect.isTrue, dart.str`true[${i}]`);
    }
    for (let i = 0; i < dart.notNull(compile_time_constant10_test_none_multi.falseTests[dartx.length]); i++) {
      compile_time_constant10_test_none_multi.falseTests[dartx.get](i).test(expect$.Expect.isFalse, dart.str`false[${i}]`);
    }
  };
  dart.fn(compile_time_constant10_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant10_test_none_multi = compile_time_constant10_test_none_multi;
});
