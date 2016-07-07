dart_library.library('language/import_collection_no_prefix_test', null, /* Imports */[
  'dart_sdk'
], function load__import_collection_no_prefix_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const import_collection_no_prefix_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  import_collection_no_prefix_test.main = function() {
    let e = new collection.SplayTreeMap();
    core.print(dart.str`"dart:collection" imported, ${e} allocated`);
  };
  dart.fn(import_collection_no_prefix_test.main, VoidTodynamic());
  // Exports:
  exports.import_collection_no_prefix_test = import_collection_no_prefix_test;
});
