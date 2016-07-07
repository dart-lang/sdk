dart_library.library('language/import_core_no_prefix_test', null, /* Imports */[
  'dart_sdk'
], function load__import_core_no_prefix_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const import_core_no_prefix_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  import_core_no_prefix_test.main = function() {
    core.print('"dart:core" imported.');
  };
  dart.fn(import_core_no_prefix_test.main, VoidTodynamic());
  // Exports:
  exports.import_core_no_prefix_test = import_core_no_prefix_test;
});
