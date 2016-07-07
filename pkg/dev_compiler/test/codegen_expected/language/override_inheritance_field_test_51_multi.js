dart_library.library('language/override_inheritance_field_test_51_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_field_test_51_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_field_test_51_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_field_test_51_multi.A = class A extends core.Object {
    set field11(_) {}
  };
  override_inheritance_field_test_51_multi.B = class B extends override_inheritance_field_test_51_multi.A {};
  override_inheritance_field_test_51_multi.I = class I extends core.Object {};
  override_inheritance_field_test_51_multi.J = class J extends core.Object {};
  override_inheritance_field_test_51_multi.Class = class Class extends override_inheritance_field_test_51_multi.B {
    new() {
      this[field11] = null;
    }
    get field11() {
      return this[field11];
    }
    set field11(value) {
      this[field11] = value;
    }
  };
  const field11 = Symbol(override_inheritance_field_test_51_multi.Class.name + "." + 'field11'.toString());
  override_inheritance_field_test_51_multi.Class[dart.implements] = () => [override_inheritance_field_test_51_multi.I, override_inheritance_field_test_51_multi.J];
  override_inheritance_field_test_51_multi.SubClass = class SubClass extends override_inheritance_field_test_51_multi.Class {
    new() {
      super.new();
    }
  };
  override_inheritance_field_test_51_multi.main = function() {
    new override_inheritance_field_test_51_multi.SubClass();
  };
  dart.fn(override_inheritance_field_test_51_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_field_test_51_multi = override_inheritance_field_test_51_multi;
});
