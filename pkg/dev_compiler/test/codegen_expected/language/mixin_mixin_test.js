dart_library.library('language/mixin_mixin_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_mixin_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_mixin_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_mixin_test.M1 = class M1 extends core.Object {
    foo() {
      return 42;
    }
  };
  dart.setSignature(mixin_mixin_test.M1, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  mixin_mixin_test.M2 = class M2 extends dart.mixin(core.Object, mixin_mixin_test.M1) {};
  mixin_mixin_test.S = class S extends core.Object {};
  mixin_mixin_test.C = class C extends dart.mixin(mixin_mixin_test.S, mixin_mixin_test.M2) {
    new() {
      super.new();
    }
  };
  mixin_mixin_test.main = function() {
    let c = new mixin_mixin_test.C();
    expect$.Expect.isTrue(mixin_mixin_test.S.is(c));
    expect$.Expect.isTrue(mixin_mixin_test.M1.is(c));
    expect$.Expect.isTrue(mixin_mixin_test.M2.is(c));
    expect$.Expect.isTrue(mixin_mixin_test.C.is(c));
    expect$.Expect.equals(42, c.foo());
  };
  dart.fn(mixin_mixin_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_mixin_test = mixin_mixin_test;
});
