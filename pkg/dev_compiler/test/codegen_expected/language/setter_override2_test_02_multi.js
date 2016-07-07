dart_library.library('language/setter_override2_test_02_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setter_override2_test_02_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setter_override2_test_02_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  setter_override2_test_02_multi.A = class A extends core.Object {
    foo() {
      return 42;
    }
  };
  dart.setSignature(setter_override2_test_02_multi.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  setter_override2_test_02_multi.B = class B extends setter_override2_test_02_multi.A {
    new() {
      this.foo_ = null;
    }
    set foo(value) {
      this.foo_ = value;
    }
  };
  setter_override2_test_02_multi.main = function() {
    let b = new setter_override2_test_02_multi.B();
    b.foo = 42;
    expect$.Expect.equals(42, b.foo_);
  };
  dart.fn(setter_override2_test_02_multi.main, VoidTodynamic());
  // Exports:
  exports.setter_override2_test_02_multi = setter_override2_test_02_multi;
});
