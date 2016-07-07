dart_library.library('language/type_propagation_in_for_update_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_propagation_in_for_update_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_propagation_in_for_update_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_propagation_in_for_update_test.bar = function() {
    return 'foo';
  };
  dart.fn(type_propagation_in_for_update_test.bar, VoidTodynamic());
  type_propagation_in_for_update_test.main = function() {
    expect$.Expect.throws(type_propagation_in_for_update_test.foo1);
    expect$.Expect.throws(type_propagation_in_for_update_test.foo2);
  };
  dart.fn(type_propagation_in_for_update_test.main, VoidTodynamic());
  type_propagation_in_for_update_test.foo1 = function() {
    let a = type_propagation_in_for_update_test.bar();
    for (;; a = 1 + dart.notNull(core.num._check(a))) {
      if (!dart.equals(a, 'foo')) return;
    }
  };
  dart.fn(type_propagation_in_for_update_test.foo1, VoidTodynamic());
  type_propagation_in_for_update_test.foo2 = function() {
    let a = type_propagation_in_for_update_test.bar();
    for (;; a = 1 + dart.notNull(core.num._check(a))) {
      if (!dart.equals(a, 'foo')) break;
    }
  };
  dart.fn(type_propagation_in_for_update_test.foo2, VoidTodynamic());
  // Exports:
  exports.type_propagation_in_for_update_test = type_propagation_in_for_update_test;
});
