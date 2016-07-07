dart_library.library('language/parameter_metadata_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__parameter_metadata_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const parameter_metadata_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAndFnTodynamic = () => (dynamicAndFnTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic, dynamicTodynamic()])))();
  let FnTodynamic = () => (FnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dynamicAndFnTodynamic()])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  parameter_metadata_test_none_multi.test = function(f) {
  };
  dart.fn(parameter_metadata_test_none_multi.test, FnTodynamic());
  parameter_metadata_test_none_multi.main = function() {
    parameter_metadata_test_none_multi.test(null);
  };
  dart.fn(parameter_metadata_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.parameter_metadata_test_none_multi = parameter_metadata_test_none_multi;
});
