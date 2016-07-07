dart_library.library('language/override_inheritance_method_test_25_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_method_test_25_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_method_test_25_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_method_test_25_multi.A = class A extends core.Object {
    method25() {
      return null;
    }
  };
  dart.setSignature(override_inheritance_method_test_25_multi.A, {
    methods: () => ({method25: dart.definiteFunctionType(dart.dynamic, [])})
  });
  override_inheritance_method_test_25_multi.B = class B extends override_inheritance_method_test_25_multi.A {};
  override_inheritance_method_test_25_multi.I = class I extends core.Object {};
  override_inheritance_method_test_25_multi.J = class J extends core.Object {};
  override_inheritance_method_test_25_multi.Class = class Class extends override_inheritance_method_test_25_multi.B {
    method25() {}
  };
  override_inheritance_method_test_25_multi.Class[dart.implements] = () => [override_inheritance_method_test_25_multi.I, override_inheritance_method_test_25_multi.J];
  dart.setSignature(override_inheritance_method_test_25_multi.Class, {
    methods: () => ({method25: dart.definiteFunctionType(dart.void, [])})
  });
  override_inheritance_method_test_25_multi.SubClass = class SubClass extends override_inheritance_method_test_25_multi.Class {};
  override_inheritance_method_test_25_multi.main = function() {
    new override_inheritance_method_test_25_multi.SubClass();
  };
  dart.fn(override_inheritance_method_test_25_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_method_test_25_multi = override_inheritance_method_test_25_multi;
});
