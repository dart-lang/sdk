dart_library.library('language/override_inheritance_no_such_method_test_05_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_no_such_method_test_05_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_no_such_method_test_05_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_no_such_method_test_05_multi.A = class A extends core.Object {};
  override_inheritance_no_such_method_test_05_multi.I = class I extends core.Object {};
  override_inheritance_no_such_method_test_05_multi.Class1 = class Class1 extends override_inheritance_no_such_method_test_05_multi.A {
    method5() {
      return this.noSuchMethod(new dart.InvocationImpl('method5', [], {isMethod: true}));
    }
  };
  override_inheritance_no_such_method_test_05_multi.Class1[dart.implements] = () => [override_inheritance_no_such_method_test_05_multi.I];
  override_inheritance_no_such_method_test_05_multi.B = class B extends core.Object {};
  override_inheritance_no_such_method_test_05_multi.Class2 = class Class2 extends override_inheritance_no_such_method_test_05_multi.B {};
  override_inheritance_no_such_method_test_05_multi.main = function() {
    new override_inheritance_no_such_method_test_05_multi.Class1();
    new override_inheritance_no_such_method_test_05_multi.Class2();
  };
  dart.fn(override_inheritance_no_such_method_test_05_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_no_such_method_test_05_multi = override_inheritance_no_such_method_test_05_multi;
});
