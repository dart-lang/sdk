dart_library.library('language/getter_override_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__getter_override_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const getter_override_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  getter_override_test_none_multi.A = class A extends core.Object {};
  getter_override_test_none_multi.B = class B extends getter_override_test_none_multi.A {
    static get foo() {
      return 42;
    }
  };
  getter_override_test_none_multi.main = function() {
    expect$.Expect.equals(42, getter_override_test_none_multi.B.foo);
  };
  dart.fn(getter_override_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.getter_override_test_none_multi = getter_override_test_none_multi;
});
