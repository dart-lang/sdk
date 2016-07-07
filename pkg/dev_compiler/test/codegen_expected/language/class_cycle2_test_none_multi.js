dart_library.library('language/class_cycle2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__class_cycle2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const class_cycle2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  class_cycle2_test_none_multi.B = class B extends core.Object {};
  class_cycle2_test_none_multi.C = class C extends class_cycle2_test_none_multi.B {};
  class_cycle2_test_none_multi.A = class A extends class_cycle2_test_none_multi.B {};
  class_cycle2_test_none_multi.main = function() {
  };
  dart.fn(class_cycle2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.class_cycle2_test_none_multi = class_cycle2_test_none_multi;
});
