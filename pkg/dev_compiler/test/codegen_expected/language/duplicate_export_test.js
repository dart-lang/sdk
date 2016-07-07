dart_library.library('language/duplicate_export_test', null, /* Imports */[
  'dart_sdk'
], function load__duplicate_export_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const duplicate_export_test = Object.create(null);
  const duplicate_import_liba = Object.create(null);
  const duplicate_export_liba = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  duplicate_export_test.main = function() {
  };
  dart.fn(duplicate_export_test.main, VoidTovoid());
  duplicate_import_liba.methodOrClass = function() {
  };
  dart.fn(duplicate_import_liba.methodOrClass, VoidTovoid());
  duplicate_export_test.methodOrClass = duplicate_import_liba.methodOrClass;
  duplicate_import_liba.field = null;
  duplicate_export_test.field = duplicate_import_liba.field;
  duplicate_import_liba.method = function() {
  };
  dart.fn(duplicate_import_liba.method, VoidTovoid());
  duplicate_export_test.method = duplicate_import_liba.method;
  duplicate_import_liba.Class = class Class extends core.Object {};
  duplicate_export_test.Class = duplicate_import_liba.Class;
  duplicate_export_test.field = duplicate_import_liba.field;
  duplicate_export_test.methodOrClass = duplicate_import_liba.methodOrClass;
  duplicate_export_test.field = duplicate_import_liba.field;
  duplicate_export_test.Class = duplicate_import_liba.Class;
  duplicate_export_test.method = duplicate_import_liba.method;
  duplicate_export_test.field = duplicate_import_liba.field;
  duplicate_export_liba.methodOrClass = duplicate_import_liba.methodOrClass;
  duplicate_export_liba.field = duplicate_import_liba.field;
  duplicate_export_liba.method = duplicate_import_liba.method;
  duplicate_export_liba.Class = duplicate_import_liba.Class;
  duplicate_export_liba.field = duplicate_import_liba.field;
  // Exports:
  exports.duplicate_export_test = duplicate_export_test;
  exports.duplicate_import_liba = duplicate_import_liba;
  exports.duplicate_export_liba = duplicate_export_liba;
});
