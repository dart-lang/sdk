dart_library.library('language/override_inheritance_method_test_07_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_method_test_07_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_method_test_07_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_method_test_07_multi.A = class A extends core.Object {
    method7(a) {
      if (a === void 0) a = null;
      return null;
    }
  };
  dart.setSignature(override_inheritance_method_test_07_multi.A, {
    methods: () => ({method7: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])})
  });
  override_inheritance_method_test_07_multi.B = class B extends override_inheritance_method_test_07_multi.A {};
  override_inheritance_method_test_07_multi.I = class I extends core.Object {};
  override_inheritance_method_test_07_multi.J = class J extends core.Object {};
  override_inheritance_method_test_07_multi.Class = class Class extends override_inheritance_method_test_07_multi.B {
    method7(a) {
      if (a === void 0) a = null;
      return null;
    }
  };
  override_inheritance_method_test_07_multi.Class[dart.implements] = () => [override_inheritance_method_test_07_multi.I, override_inheritance_method_test_07_multi.J];
  override_inheritance_method_test_07_multi.SubClass = class SubClass extends override_inheritance_method_test_07_multi.Class {};
  override_inheritance_method_test_07_multi.main = function() {
    new override_inheritance_method_test_07_multi.SubClass();
  };
  dart.fn(override_inheritance_method_test_07_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_method_test_07_multi = override_inheritance_method_test_07_multi;
});
