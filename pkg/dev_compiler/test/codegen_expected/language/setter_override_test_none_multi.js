dart_library.library('language/setter_override_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setter_override_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setter_override_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  setter_override_test_none_multi.A = class A extends core.Object {};
  setter_override_test_none_multi.B = class B extends setter_override_test_none_multi.A {
    static set foo(value) {
      setter_override_test_none_multi.B.foo_ = value;
    }
  };
  setter_override_test_none_multi.B.foo_ = null;
  setter_override_test_none_multi.main = function() {
    setter_override_test_none_multi.B.foo = 42;
    expect$.Expect.equals(42, setter_override_test_none_multi.B.foo_);
  };
  dart.fn(setter_override_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.setter_override_test_none_multi = setter_override_test_none_multi;
});
