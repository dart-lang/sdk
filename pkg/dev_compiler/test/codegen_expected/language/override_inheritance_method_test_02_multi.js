dart_library.library('language/override_inheritance_method_test_02_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_method_test_02_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_method_test_02_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_method_test_02_multi.A = class A extends core.Object {
    method2(a) {
      return null;
    }
  };
  dart.setSignature(override_inheritance_method_test_02_multi.A, {
    methods: () => ({method2: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  override_inheritance_method_test_02_multi.B = class B extends override_inheritance_method_test_02_multi.A {};
  override_inheritance_method_test_02_multi.I = class I extends core.Object {};
  override_inheritance_method_test_02_multi.J = class J extends core.Object {};
  override_inheritance_method_test_02_multi.Class = class Class extends override_inheritance_method_test_02_multi.B {
    method2(b) {
      return null;
    }
  };
  override_inheritance_method_test_02_multi.Class[dart.implements] = () => [override_inheritance_method_test_02_multi.I, override_inheritance_method_test_02_multi.J];
  override_inheritance_method_test_02_multi.SubClass = class SubClass extends override_inheritance_method_test_02_multi.Class {};
  override_inheritance_method_test_02_multi.main = function() {
    new override_inheritance_method_test_02_multi.SubClass();
  };
  dart.fn(override_inheritance_method_test_02_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_method_test_02_multi = override_inheritance_method_test_02_multi;
});
