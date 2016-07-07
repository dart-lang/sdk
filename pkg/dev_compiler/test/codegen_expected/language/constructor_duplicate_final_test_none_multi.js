dart_library.library('language/constructor_duplicate_final_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__constructor_duplicate_final_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constructor_duplicate_final_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor_duplicate_final_test_none_multi.Class = class Class extends core.Object {
    new() {
      this.f = 10;
    }
  };
  constructor_duplicate_final_test_none_multi.main = function() {
  };
  dart.fn(constructor_duplicate_final_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.constructor_duplicate_final_test_none_multi = constructor_duplicate_final_test_none_multi;
});
