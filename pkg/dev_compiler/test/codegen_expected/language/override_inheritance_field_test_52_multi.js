dart_library.library('language/override_inheritance_field_test_52_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_field_test_52_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_field_test_52_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_field_test_52_multi.A = class A extends core.Object {
    set field12(_) {}
  };
  override_inheritance_field_test_52_multi.B = class B extends override_inheritance_field_test_52_multi.A {};
  override_inheritance_field_test_52_multi.I = class I extends core.Object {};
  override_inheritance_field_test_52_multi.J = class J extends core.Object {};
  override_inheritance_field_test_52_multi.Class = class Class extends override_inheritance_field_test_52_multi.B {
    new() {
      this[field12] = null;
    }
    get field12() {
      return this[field12];
    }
    set field12(value) {
      this[field12] = value;
    }
  };
  const field12 = Symbol(override_inheritance_field_test_52_multi.Class.name + "." + 'field12'.toString());
  override_inheritance_field_test_52_multi.Class[dart.implements] = () => [override_inheritance_field_test_52_multi.I, override_inheritance_field_test_52_multi.J];
  override_inheritance_field_test_52_multi.SubClass = class SubClass extends override_inheritance_field_test_52_multi.Class {
    new() {
      super.new();
    }
  };
  override_inheritance_field_test_52_multi.main = function() {
    new override_inheritance_field_test_52_multi.SubClass();
  };
  dart.fn(override_inheritance_field_test_52_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_field_test_52_multi = override_inheritance_field_test_52_multi;
});
