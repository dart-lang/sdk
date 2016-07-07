dart_library.library('language/call_non_method_field_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__call_non_method_field_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const call_non_method_field_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  call_non_method_field_test_none_multi.Fisk = class Fisk extends core.Object {
    new() {
      this.i = null;
    }
  };
  call_non_method_field_test_none_multi.Hest = class Hest extends call_non_method_field_test_none_multi.Fisk {
    new() {
      super.new();
    }
  };
  call_non_method_field_test_none_multi.main = function() {
    let x1 = new call_non_method_field_test_none_multi.Fisk();
    if (false) {
    }
    let x2 = new call_non_method_field_test_none_multi.Hest();
    if (false) {
    }
  };
  dart.fn(call_non_method_field_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.call_non_method_field_test_none_multi = call_non_method_field_test_none_multi;
});
