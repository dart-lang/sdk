dart_library.library('language/mixin_is_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_is_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_is_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_is_test.S = class S extends core.Object {};
  mixin_is_test.M1 = class M1 extends core.Object {};
  mixin_is_test.M2 = class M2 extends core.Object {};
  mixin_is_test.C = class C extends dart.mixin(mixin_is_test.S, mixin_is_test.M1) {
    new() {
      super.new();
    }
  };
  mixin_is_test.D = class D extends dart.mixin(mixin_is_test.S, mixin_is_test.M1, mixin_is_test.M2) {
    new() {
      super.new();
    }
  };
  mixin_is_test.E = class E extends dart.mixin(mixin_is_test.S, mixin_is_test.M2, mixin_is_test.M1) {
    new() {
      super.new();
    }
  };
  mixin_is_test.F = class F extends mixin_is_test.E {};
  mixin_is_test.C_ = class C_ extends dart.mixin(mixin_is_test.S, mixin_is_test.M1) {
    new() {
      super.new();
    }
  };
  mixin_is_test.D_ = class D_ extends dart.mixin(mixin_is_test.S, mixin_is_test.M1, mixin_is_test.M2) {
    new() {
      super.new();
    }
  };
  mixin_is_test.E_ = class E_ extends dart.mixin(mixin_is_test.S, mixin_is_test.M2, mixin_is_test.M1) {
    new() {
      super.new();
    }
  };
  mixin_is_test.F_ = class F_ extends mixin_is_test.E_ {};
  mixin_is_test.main = function() {
    let c = new mixin_is_test.C();
    expect$.Expect.isTrue(mixin_is_test.C.is(c));
    expect$.Expect.isFalse(mixin_is_test.D.is(c));
    expect$.Expect.isFalse(mixin_is_test.E.is(c));
    expect$.Expect.isFalse(mixin_is_test.F.is(c));
    expect$.Expect.isTrue(mixin_is_test.S.is(c));
    expect$.Expect.isTrue(mixin_is_test.M1.is(c));
    expect$.Expect.isFalse(mixin_is_test.M2.is(c));
    let d = new mixin_is_test.D();
    expect$.Expect.isFalse(mixin_is_test.C.is(d));
    expect$.Expect.isTrue(mixin_is_test.D.is(d));
    expect$.Expect.isFalse(mixin_is_test.E.is(d));
    expect$.Expect.isFalse(mixin_is_test.F.is(d));
    expect$.Expect.isTrue(mixin_is_test.S.is(d));
    expect$.Expect.isTrue(mixin_is_test.M1.is(d));
    expect$.Expect.isTrue(mixin_is_test.M2.is(d));
    let e = new mixin_is_test.E();
    expect$.Expect.isFalse(mixin_is_test.C.is(e));
    expect$.Expect.isFalse(mixin_is_test.D.is(e));
    expect$.Expect.isTrue(mixin_is_test.E.is(e));
    expect$.Expect.isFalse(mixin_is_test.F.is(e));
    expect$.Expect.isTrue(mixin_is_test.S.is(e));
    expect$.Expect.isTrue(mixin_is_test.M1.is(e));
    expect$.Expect.isTrue(mixin_is_test.M2.is(e));
    let f = new mixin_is_test.F();
    expect$.Expect.isFalse(mixin_is_test.C.is(f));
    expect$.Expect.isFalse(mixin_is_test.D.is(f));
    expect$.Expect.isTrue(mixin_is_test.E.is(f));
    expect$.Expect.isTrue(mixin_is_test.F.is(f));
    expect$.Expect.isTrue(mixin_is_test.S.is(f));
    expect$.Expect.isTrue(mixin_is_test.M1.is(f));
    expect$.Expect.isTrue(mixin_is_test.M2.is(f));
    expect$.Expect.isFalse(mixin_is_test.C_.is(c));
    expect$.Expect.isFalse(mixin_is_test.D_.is(c));
    expect$.Expect.isFalse(mixin_is_test.E_.is(c));
    expect$.Expect.isFalse(mixin_is_test.F_.is(c));
    expect$.Expect.isFalse(mixin_is_test.C_.is(d));
    expect$.Expect.isFalse(mixin_is_test.D_.is(d));
    expect$.Expect.isFalse(mixin_is_test.E_.is(d));
    expect$.Expect.isFalse(mixin_is_test.F_.is(d));
    expect$.Expect.isFalse(mixin_is_test.C_.is(e));
    expect$.Expect.isFalse(mixin_is_test.D_.is(e));
    expect$.Expect.isFalse(mixin_is_test.E_.is(e));
    expect$.Expect.isFalse(mixin_is_test.F_.is(e));
    expect$.Expect.isFalse(mixin_is_test.C_.is(f));
    expect$.Expect.isFalse(mixin_is_test.D_.is(f));
    expect$.Expect.isFalse(mixin_is_test.E_.is(f));
    expect$.Expect.isFalse(mixin_is_test.F_.is(f));
  };
  dart.fn(mixin_is_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_is_test = mixin_is_test;
});
