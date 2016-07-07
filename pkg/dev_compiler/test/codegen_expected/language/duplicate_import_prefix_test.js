dart_library.library('language/duplicate_import_prefix_test', null, /* Imports */[
  'dart_sdk'
], function load__duplicate_import_prefix_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const duplicate_import_prefix_test = Object.create(null);
  const duplicate_import_liba = Object.create(null);
  const duplicate_import_libb = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  duplicate_import_prefix_test.main = function() {
  };
  dart.fn(duplicate_import_prefix_test.main, VoidTovoid());
  duplicate_import_liba.field = null;
  duplicate_import_liba.method = function() {
  };
  dart.fn(duplicate_import_liba.method, VoidTovoid());
  duplicate_import_liba.Class = class Class extends core.Object {};
  duplicate_import_liba.methodOrClass = function() {
  };
  dart.fn(duplicate_import_liba.methodOrClass, VoidTovoid());
  duplicate_import_libb.field = null;
  duplicate_import_libb.method = function() {
  };
  dart.fn(duplicate_import_libb.method, VoidTovoid());
  duplicate_import_libb.Class = class Class extends core.Object {};
  duplicate_import_libb.methodOrClass = class methodOrClass extends core.Object {};
  // Exports:
  exports.duplicate_import_prefix_test = duplicate_import_prefix_test;
  exports.duplicate_import_liba = duplicate_import_liba;
  exports.duplicate_import_libb = duplicate_import_libb;
});
