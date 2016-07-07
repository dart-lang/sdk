dart_library.library('language/setter_override2_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setter_override2_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setter_override2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  setter_override2_test_none_multi.A = class A extends core.Object {};
  setter_override2_test_none_multi.B = class B extends setter_override2_test_none_multi.A {
    new() {
      this.foo_ = null;
    }
    set foo(value) {
      this.foo_ = value;
    }
  };
  setter_override2_test_none_multi.main = function() {
    let b = new setter_override2_test_none_multi.B();
    b.foo = 42;
    expect$.Expect.equals(42, b.foo_);
  };
  dart.fn(setter_override2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.setter_override2_test_none_multi = setter_override2_test_none_multi;
});
