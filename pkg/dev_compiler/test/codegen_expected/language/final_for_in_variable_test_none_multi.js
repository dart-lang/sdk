dart_library.library('language/final_for_in_variable_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__final_for_in_variable_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const final_for_in_variable_test_none_multi = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  final_for_in_variable_test_none_multi.main = function() {
    for (let i of JSArrayOfint().of([1, 2, 3])) {
    }
  };
  dart.fn(final_for_in_variable_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.final_for_in_variable_test_none_multi = final_for_in_variable_test_none_multi;
});
