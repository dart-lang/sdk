dart_library.library('language/mixin_illegal_super_use_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_illegal_super_use_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_illegal_super_use_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_illegal_super_use_test_none_multi.M = class M extends core.Object {};
  mixin_illegal_super_use_test_none_multi.P0 = class P0 extends core.Object {
    foo() {
      function inner() {
      }
      dart.fn(inner, VoidTovoid());
      inner();
      dart.fn(() => {
      }, VoidTodynamic())();
      return 42;
    }
  };
  dart.setSignature(mixin_illegal_super_use_test_none_multi.P0, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  mixin_illegal_super_use_test_none_multi.P1 = class P1 extends core.Object {
    bar() {
      return 87;
    }
    test() {
      new mixin_illegal_super_use_test_none_multi.C();
      let d = new mixin_illegal_super_use_test_none_multi.D();
      let e = new mixin_illegal_super_use_test_none_multi.E();
      let f = new mixin_illegal_super_use_test_none_multi.F();
      expect$.Expect.equals(42, d.foo());
      expect$.Expect.equals(87, e.bar());
      expect$.Expect.equals(99, f.baz());
    }
  };
  dart.setSignature(mixin_illegal_super_use_test_none_multi.P1, {
    methods: () => ({
      bar: dart.definiteFunctionType(dart.dynamic, []),
      test: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  mixin_illegal_super_use_test_none_multi.P2 = class P2 extends core.Object {
    baz() {
      return 99;
    }
  };
  dart.setSignature(mixin_illegal_super_use_test_none_multi.P2, {
    methods: () => ({baz: dart.definiteFunctionType(dart.dynamic, [])})
  });
  mixin_illegal_super_use_test_none_multi.C = class C extends dart.mixin(core.Object, mixin_illegal_super_use_test_none_multi.M) {};
  mixin_illegal_super_use_test_none_multi.D = class D extends dart.mixin(core.Object, mixin_illegal_super_use_test_none_multi.P0) {};
  mixin_illegal_super_use_test_none_multi.E = class E extends dart.mixin(core.Object, mixin_illegal_super_use_test_none_multi.M, mixin_illegal_super_use_test_none_multi.P1) {};
  mixin_illegal_super_use_test_none_multi.F = class F extends dart.mixin(core.Object, mixin_illegal_super_use_test_none_multi.P2, mixin_illegal_super_use_test_none_multi.M) {};
  mixin_illegal_super_use_test_none_multi.main = function() {
    let p1 = new mixin_illegal_super_use_test_none_multi.P1();
    let p2 = new mixin_illegal_super_use_test_none_multi.P2();
    expect$.Expect.equals(87, p1.bar());
    p1.test();
    expect$.Expect.equals(99, p2.baz());
  };
  dart.fn(mixin_illegal_super_use_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.mixin_illegal_super_use_test_none_multi = mixin_illegal_super_use_test_none_multi;
});
