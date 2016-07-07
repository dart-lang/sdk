dart_library.library('language/getter_override2_test_03_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__getter_override2_test_03_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const getter_override2_test_03_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  getter_override2_test_03_multi.A = class A extends core.Object {
    set foo(value) {}
  };
  getter_override2_test_03_multi.B = class B extends getter_override2_test_03_multi.A {
    get foo() {
      return 42;
    }
    set foo(value) {
      super.foo = value;
    }
  };
  getter_override2_test_03_multi.main = function() {
    expect$.Expect.equals(42, new getter_override2_test_03_multi.B().foo);
  };
  dart.fn(getter_override2_test_03_multi.main, VoidTodynamic());
  // Exports:
  exports.getter_override2_test_03_multi = getter_override2_test_03_multi;
});
