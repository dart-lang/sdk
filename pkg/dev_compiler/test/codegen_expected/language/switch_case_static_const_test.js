dart_library.library('language/switch_case_static_const_test', null, /* Imports */[
  'dart_sdk'
], function load__switch_case_static_const_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const switch_case_static_const_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  switch_case_static_const_test.A = class A extends core.Object {};
  switch_case_static_const_test.A.S = 'A.S';
  switch_case_static_const_test.S = 'S';
  switch_case_static_const_test.foo = function(p) {
    switch (p) {
      case switch_case_static_const_test.S:
      {
        break;
      }
      case switch_case_static_const_test.A.S:
      {
        break;
      }
      case 'abc':
      {
        break;
      }
    }
  };
  dart.fn(switch_case_static_const_test.foo, dynamicTodynamic());
  switch_case_static_const_test.main = function() {
    switch_case_static_const_test.foo('p');
  };
  dart.fn(switch_case_static_const_test.main, VoidTodynamic());
  // Exports:
  exports.switch_case_static_const_test = switch_case_static_const_test;
});
