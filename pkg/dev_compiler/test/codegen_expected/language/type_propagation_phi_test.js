dart_library.library('language/type_propagation_phi_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_propagation_phi_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_propagation_phi_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  type_propagation_phi_test.bar = function() {
    return 490;
  };
  dart.fn(type_propagation_phi_test.bar, VoidTodynamic());
  type_propagation_phi_test.bar2 = function() {
    return 0;
  };
  dart.fn(type_propagation_phi_test.bar2, VoidTodynamic());
  type_propagation_phi_test.foo = function(b) {
    let x = type_propagation_phi_test.bar();
    let x2 = x;
    if (dart.test(b)) x2 = type_propagation_phi_test.bar2();
    let x3 = 9 + dart.notNull(core.num._check(x));
    return dart.dsend(x2, '+', x3);
  };
  dart.fn(type_propagation_phi_test.foo, dynamicTodynamic());
  type_propagation_phi_test.main = function() {
    expect$.Expect.equals(499, type_propagation_phi_test.foo(true));
  };
  dart.fn(type_propagation_phi_test.main, VoidTodynamic());
  // Exports:
  exports.type_propagation_phi_test = type_propagation_phi_test;
});
