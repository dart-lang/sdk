dart_library.library('language/override_field_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_field_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_field_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_field_test_none_multi.A = class A extends core.Object {
    new() {
      this.instanceFieldInA = null;
    }
  };
  override_field_test_none_multi.A.staticFieldInA = null;
  override_field_test_none_multi.B = class B extends override_field_test_none_multi.A {
    new() {
      super.new();
    }
  };
  override_field_test_none_multi.main = function() {
    let x = new override_field_test_none_multi.B();
  };
  dart.fn(override_field_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.override_field_test_none_multi = override_field_test_none_multi;
});
