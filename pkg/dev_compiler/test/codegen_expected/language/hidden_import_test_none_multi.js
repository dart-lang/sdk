dart_library.library('language/hidden_import_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__hidden_import_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const hidden_import_test_none_multi = Object.create(null);
  const hidden_import_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  hidden_import_test_none_multi.main = function() {
  };
  dart.fn(hidden_import_test_none_multi.main, VoidTodynamic());
  hidden_import_lib.Future = class Future extends core.Object {};
  // Exports:
  exports.hidden_import_test_none_multi = hidden_import_test_none_multi;
  exports.hidden_import_lib = hidden_import_lib;
});
