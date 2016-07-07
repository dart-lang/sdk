dart_library.library('language/mixin_implements_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_implements_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_implements_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_implements_test.I0 = class I0 extends core.Object {};
  mixin_implements_test.I1 = class I1 extends core.Object {};
  mixin_implements_test.I2 = class I2 extends core.Object {};
  mixin_implements_test.I2[dart.implements] = () => [mixin_implements_test.I0, mixin_implements_test.I1];
  mixin_implements_test.M = class M extends core.Object {
    foo() {
      return 42;
    }
    bar() {
      return 87;
    }
  };
  dart.setSignature(mixin_implements_test.M, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  mixin_implements_test.C0 = class C0 extends dart.mixin(core.Object, mixin_implements_test.M) {};
  mixin_implements_test.C1 = class C1 extends dart.mixin(core.Object, mixin_implements_test.M) {};
  mixin_implements_test.C2 = class C2 extends dart.mixin(core.Object, mixin_implements_test.M) {};
  mixin_implements_test.C3 = class C3 extends dart.mixin(core.Object, mixin_implements_test.M) {};
  mixin_implements_test.C4 = class C4 extends dart.mixin(core.Object, mixin_implements_test.M) {};
  mixin_implements_test.C5 = class C5 extends dart.mixin(core.Object, mixin_implements_test.M) {};
  mixin_implements_test.main = function() {
    let c0 = new mixin_implements_test.C0();
    expect$.Expect.equals(42, c0.foo());
    expect$.Expect.equals(87, c0.bar());
    expect$.Expect.isTrue(mixin_implements_test.M.is(c0));
    expect$.Expect.isFalse(mixin_implements_test.I0.is(c0));
    expect$.Expect.isFalse(mixin_implements_test.I1.is(c0));
    expect$.Expect.isFalse(mixin_implements_test.I2.is(c0));
    let c1 = new mixin_implements_test.C1();
    expect$.Expect.equals(42, c1.foo());
    expect$.Expect.equals(87, c1.bar());
    expect$.Expect.isTrue(mixin_implements_test.M.is(c1));
    expect$.Expect.isTrue(mixin_implements_test.I0.is(c1));
    expect$.Expect.isFalse(mixin_implements_test.I1.is(c1));
    expect$.Expect.isFalse(mixin_implements_test.I2.is(c1));
    let c2 = new mixin_implements_test.C2();
    expect$.Expect.equals(42, c2.foo());
    expect$.Expect.equals(87, c2.bar());
    expect$.Expect.isTrue(mixin_implements_test.M.is(c2));
    expect$.Expect.isFalse(mixin_implements_test.I0.is(c2));
    expect$.Expect.isTrue(mixin_implements_test.I1.is(c2));
    expect$.Expect.isFalse(mixin_implements_test.I2.is(c1));
    let c3 = new mixin_implements_test.C3();
    expect$.Expect.equals(42, c3.foo());
    expect$.Expect.equals(87, c3.bar());
    expect$.Expect.isTrue(mixin_implements_test.M.is(c3));
    expect$.Expect.isTrue(mixin_implements_test.I0.is(c3));
    expect$.Expect.isTrue(mixin_implements_test.I1.is(c3));
    expect$.Expect.isFalse(mixin_implements_test.I2.is(c1));
    let c4 = new mixin_implements_test.C4();
    expect$.Expect.equals(42, c4.foo());
    expect$.Expect.equals(87, c4.bar());
    expect$.Expect.isTrue(mixin_implements_test.M.is(c4));
    expect$.Expect.isTrue(mixin_implements_test.I0.is(c4));
    expect$.Expect.isTrue(mixin_implements_test.I1.is(c4));
    expect$.Expect.isFalse(mixin_implements_test.I2.is(c1));
    let c5 = new mixin_implements_test.C5();
    expect$.Expect.equals(42, c5.foo());
    expect$.Expect.equals(87, c5.bar());
    expect$.Expect.isTrue(mixin_implements_test.M.is(c5));
    expect$.Expect.isTrue(mixin_implements_test.I0.is(c5));
    expect$.Expect.isTrue(mixin_implements_test.I1.is(c5));
    expect$.Expect.isTrue(mixin_implements_test.I2.is(c5));
  };
  dart.fn(mixin_implements_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_implements_test = mixin_implements_test;
});
