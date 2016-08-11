dart_library.library('language/export_main_override_test', null, /* Imports */[
  'dart_sdk'
], function load__export_main_override_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const export_main_override_test = Object.create(null);
  const top_level_entry_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  export_main_override_test.main = function() {
    core.print('export_main_override');
  };
  dart.fn(export_main_override_test.main, VoidTodynamic());
  top_level_entry_test.main = function() {
  };
  dart.fn(top_level_entry_test.main, VoidTodynamic());
  // Exports:
  exports.export_main_override_test = export_main_override_test;
  exports.top_level_entry_test = top_level_entry_test;
});
