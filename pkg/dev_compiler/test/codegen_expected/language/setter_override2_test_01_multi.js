dart_library.library('language/setter_override2_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setter_override2_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setter_override2_test_01_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  setter_override2_test_01_multi.A = class A extends core.Object {
    get foo() {
      return 42;
    }
  };
  setter_override2_test_01_multi.B = class B extends setter_override2_test_01_multi.A {
    new() {
      this.foo_ = null;
    }
    set foo(value) {
      this.foo_ = value;
    }
    get foo() {
      return super.foo;
    }
  };
  setter_override2_test_01_multi.main = function() {
    let b = new setter_override2_test_01_multi.B();
    b.foo = 42;
    expect$.Expect.equals(42, b.foo_);
  };
  dart.fn(setter_override2_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.setter_override2_test_01_multi = setter_override2_test_01_multi;
});
