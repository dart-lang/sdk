dart_library.library('language/import_core_test', null, /* Imports */[
  'dart_sdk'
], function load__import_core_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const import_core_test = Object.create(null);
  let MapOfint$String = () => (MapOfint$String = dart.constFn(core.Map$(core.int, core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  import_core_test.main = function() {
    let test = MapOfint$String().new();
    let value = false;
    let variable = 10;
    let intval = 10;
  };
  dart.fn(import_core_test.main, VoidTovoid());
  // Exports:
  exports.import_core_test = import_core_test;
});
