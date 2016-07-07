dart_library.library('language/override_inheritance_abstract_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_abstract_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_abstract_test_01_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_abstract_test_01_multi.A = class A extends core.Object {};
  override_inheritance_abstract_test_01_multi.I = class I extends core.Object {};
  override_inheritance_abstract_test_01_multi.J = class J extends core.Object {};
  override_inheritance_abstract_test_01_multi.Class = class Class extends override_inheritance_abstract_test_01_multi.A {
    method1() {}
  };
  override_inheritance_abstract_test_01_multi.Class[dart.implements] = () => [override_inheritance_abstract_test_01_multi.I, override_inheritance_abstract_test_01_multi.J];
  dart.setSignature(override_inheritance_abstract_test_01_multi.Class, {
    methods: () => ({method1: dart.definiteFunctionType(dart.dynamic, [])})
  });
  override_inheritance_abstract_test_01_multi.main = function() {
    new override_inheritance_abstract_test_01_multi.Class();
  };
  dart.fn(override_inheritance_abstract_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_abstract_test_01_multi = override_inheritance_abstract_test_01_multi;
});
