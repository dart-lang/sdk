dart_library.library('language/mixin_override_regression_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_override_regression_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_override_regression_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_override_regression_test.C0 = class C0 extends core.Object {
    m1() {
      return 5;
    }
    m2() {
      return this.m1();
    }
  };
  dart.setSignature(mixin_override_regression_test.C0, {
    methods: () => ({
      m1: dart.definiteFunctionType(core.int, []),
      m2: dart.definiteFunctionType(core.int, [])
    })
  });
  mixin_override_regression_test.C1 = class C1 extends dart.mixin(core.Object, mixin_override_regression_test.C0) {};
  mixin_override_regression_test.D = class D extends core.Object {
    m1() {
      return 7;
    }
  };
  dart.setSignature(mixin_override_regression_test.D, {
    methods: () => ({m1: dart.definiteFunctionType(core.int, [])})
  });
  mixin_override_regression_test.E0 = class E0 extends dart.mixin(mixin_override_regression_test.C0, mixin_override_regression_test.D) {};
  mixin_override_regression_test.E1 = class E1 extends dart.mixin(mixin_override_regression_test.C1, mixin_override_regression_test.D) {};
  mixin_override_regression_test.main = function() {
    expect$.Expect.equals(7, new mixin_override_regression_test.E0().m2());
    expect$.Expect.equals(7, new mixin_override_regression_test.E1().m2());
  };
  dart.fn(mixin_override_regression_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_override_regression_test = mixin_override_regression_test;
});
