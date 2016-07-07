dart_library.library('language/field_type_check_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__field_type_check_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const field_type_check_test_none_multi = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  field_type_check_test_none_multi.A = class A extends core.Object {
    new() {
      this.e = null;
    }
  };
  field_type_check_test_none_multi.main = function() {
  };
  dart.fn(field_type_check_test_none_multi.main, VoidToint());
  // Exports:
  exports.field_type_check_test_none_multi = field_type_check_test_none_multi;
});
