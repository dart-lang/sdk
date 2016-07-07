dart_library.library('language/dynamic2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__dynamic2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const dynamic2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dynamic2_test_none_multi.A = class A extends core.Object {};
  dynamic2_test_none_multi.main = function() {
    new dynamic2_test_none_multi.A();
  };
  dart.fn(dynamic2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.dynamic2_test_none_multi = dynamic2_test_none_multi;
});
