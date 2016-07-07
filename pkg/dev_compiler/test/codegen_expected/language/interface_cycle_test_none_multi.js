dart_library.library('language/interface_cycle_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__interface_cycle_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const interface_cycle_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  interface_cycle_test_none_multi.C = class C extends core.Object {};
  interface_cycle_test_none_multi.C[dart.implements] = () => [interface_cycle_test_none_multi.B];
  interface_cycle_test_none_multi.A = class A extends core.Object {};
  interface_cycle_test_none_multi.A[dart.implements] = () => [interface_cycle_test_none_multi.B];
  interface_cycle_test_none_multi.B = class B extends core.Object {};
  interface_cycle_test_none_multi.main = function() {
  };
  dart.fn(interface_cycle_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.interface_cycle_test_none_multi = interface_cycle_test_none_multi;
});
