dart_library.library('language/override_field_test_03_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_field_test_03_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_field_test_03_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_field_test_03_multi.A = class A extends core.Object {
    new() {
      this.instanceFieldInA = null;
    }
  };
  override_field_test_03_multi.A.staticFieldInA = null;
  override_field_test_03_multi.B = class B extends override_field_test_03_multi.A {
    new() {
      super.new();
    }
  };
  dart.defineLazy(override_field_test_03_multi.B, {
    get staticFieldInA() {
      return null;
    },
    set staticFieldInA(_) {}
  });
  override_field_test_03_multi.main = function() {
    let x = new override_field_test_03_multi.B();
  };
  dart.fn(override_field_test_03_multi.main, VoidTodynamic());
  // Exports:
  exports.override_field_test_03_multi = override_field_test_03_multi;
});
