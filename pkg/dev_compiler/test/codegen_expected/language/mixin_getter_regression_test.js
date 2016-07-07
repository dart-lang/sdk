dart_library.library('language/mixin_getter_regression_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_getter_regression_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_getter_regression_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_getter_regression_test.C = class C extends core.Object {
    new() {
      this.x = null;
    }
    get y() {
      return this.x;
    }
  };
  mixin_getter_regression_test.E = class E extends core.Object {
    new() {
      this.z = 10;
    }
  };
  mixin_getter_regression_test.D = class D extends dart.mixin(mixin_getter_regression_test.E, mixin_getter_regression_test.C) {
    new() {
      this.w = 42;
      super.new();
    }
  };
  mixin_getter_regression_test.main = function() {
    let d = new mixin_getter_regression_test.D();
    d.x = 37;
    expect$.Expect.equals(37, d.x);
    expect$.Expect.equals(10, d.z);
    expect$.Expect.equals(42, d.w);
    expect$.Expect.equals(37, d.y);
  };
  dart.fn(mixin_getter_regression_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_getter_regression_test = mixin_getter_regression_test;
});
