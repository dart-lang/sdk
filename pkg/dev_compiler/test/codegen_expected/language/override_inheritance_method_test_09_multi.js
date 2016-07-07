dart_library.library('language/override_inheritance_method_test_09_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_method_test_09_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_method_test_09_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_method_test_09_multi.A = class A extends core.Object {
    method9(a, b, c) {
      if (a === void 0) a = null;
      if (b === void 0) b = null;
      if (c === void 0) c = null;
      return null;
    }
  };
  dart.setSignature(override_inheritance_method_test_09_multi.A, {
    methods: () => ({method9: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic, dart.dynamic, dart.dynamic])})
  });
  override_inheritance_method_test_09_multi.B = class B extends override_inheritance_method_test_09_multi.A {};
  override_inheritance_method_test_09_multi.I = class I extends core.Object {};
  override_inheritance_method_test_09_multi.J = class J extends core.Object {};
  override_inheritance_method_test_09_multi.Class = class Class extends override_inheritance_method_test_09_multi.B {
    method9(b, d, a, c) {
      if (b === void 0) b = null;
      if (d === void 0) d = null;
      if (a === void 0) a = null;
      if (c === void 0) c = null;
      return null;
    }
  };
  override_inheritance_method_test_09_multi.Class[dart.implements] = () => [override_inheritance_method_test_09_multi.I, override_inheritance_method_test_09_multi.J];
  dart.setSignature(override_inheritance_method_test_09_multi.Class, {
    methods: () => ({method9: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])})
  });
  override_inheritance_method_test_09_multi.SubClass = class SubClass extends override_inheritance_method_test_09_multi.Class {};
  override_inheritance_method_test_09_multi.main = function() {
    new override_inheritance_method_test_09_multi.SubClass();
  };
  dart.fn(override_inheritance_method_test_09_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_method_test_09_multi = override_inheritance_method_test_09_multi;
});
