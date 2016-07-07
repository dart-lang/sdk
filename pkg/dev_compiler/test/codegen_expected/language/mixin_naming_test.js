dart_library.library('language/mixin_naming_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_naming_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_naming_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_naming_test.S = class S extends core.Object {};
  mixin_naming_test.M1 = class M1 extends core.Object {};
  mixin_naming_test.M2 = class M2 extends core.Object {};
  mixin_naming_test.M3 = class M3 extends core.Object {};
  mixin_naming_test.C = class C extends dart.mixin(mixin_naming_test.S, mixin_naming_test.M1, mixin_naming_test.M2, mixin_naming_test.M3) {
    new() {
      super.new();
    }
  };
  mixin_naming_test.D = class D extends dart.mixin(mixin_naming_test.S, mixin_naming_test.M1, mixin_naming_test.M2, mixin_naming_test.M3) {};
  mixin_naming_test.S_M1 = class S_M1 extends core.Object {};
  mixin_naming_test.S_M1_M2 = class S_M1_M2 extends core.Object {};
  mixin_naming_test.main = function() {
    let c = new mixin_naming_test.C();
    expect$.Expect.isTrue(mixin_naming_test.C.is(c));
    expect$.Expect.isFalse(mixin_naming_test.D.is(c));
    expect$.Expect.isTrue(mixin_naming_test.S.is(c));
    expect$.Expect.isFalse(mixin_naming_test.S_M1.is(c));
    expect$.Expect.isFalse(mixin_naming_test.S_M1_M2.is(c));
    let d = new mixin_naming_test.D();
    expect$.Expect.isFalse(mixin_naming_test.C.is(d));
    expect$.Expect.isTrue(mixin_naming_test.D.is(d));
    expect$.Expect.isTrue(mixin_naming_test.S.is(d));
    expect$.Expect.isFalse(mixin_naming_test.S_M1.is(d));
    expect$.Expect.isFalse(mixin_naming_test.S_M1_M2.is(d));
    let sm = new mixin_naming_test.S_M1();
    expect$.Expect.isFalse(mixin_naming_test.C.is(sm));
    expect$.Expect.isFalse(mixin_naming_test.D.is(sm));
    expect$.Expect.isFalse(mixin_naming_test.S.is(sm));
    expect$.Expect.isTrue(mixin_naming_test.S_M1.is(sm));
    expect$.Expect.isFalse(mixin_naming_test.S_M1_M2.is(sm));
    let smm = new mixin_naming_test.S_M1_M2();
    expect$.Expect.isFalse(mixin_naming_test.C.is(smm));
    expect$.Expect.isFalse(mixin_naming_test.D.is(smm));
    expect$.Expect.isFalse(mixin_naming_test.S.is(smm));
    expect$.Expect.isFalse(mixin_naming_test.S_M1.is(smm));
    expect$.Expect.isTrue(mixin_naming_test.S_M1_M2.is(smm));
  };
  dart.fn(mixin_naming_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_naming_test = mixin_naming_test;
});
