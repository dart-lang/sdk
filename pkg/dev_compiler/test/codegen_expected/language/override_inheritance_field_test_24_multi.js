dart_library.library('language/override_inheritance_field_test_24_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_field_test_24_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_field_test_24_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_field_test_24_multi.A = class A extends core.Object {
    set setter4(_) {
      return null;
    }
  };
  override_inheritance_field_test_24_multi.B = class B extends override_inheritance_field_test_24_multi.A {};
  override_inheritance_field_test_24_multi.I = class I extends core.Object {};
  override_inheritance_field_test_24_multi.J = class J extends core.Object {};
  override_inheritance_field_test_24_multi.Class = class Class extends override_inheritance_field_test_24_multi.B {
    set setter4(_) {}
  };
  override_inheritance_field_test_24_multi.Class[dart.implements] = () => [override_inheritance_field_test_24_multi.I, override_inheritance_field_test_24_multi.J];
  override_inheritance_field_test_24_multi.SubClass = class SubClass extends override_inheritance_field_test_24_multi.Class {};
  override_inheritance_field_test_24_multi.main = function() {
    new override_inheritance_field_test_24_multi.SubClass();
  };
  dart.fn(override_inheritance_field_test_24_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_field_test_24_multi = override_inheritance_field_test_24_multi;
});
