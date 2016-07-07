dart_library.library('language/override_inheritance_generic_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_generic_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_generic_test_none_multi = Object.create(null);
  let A = () => (A = dart.constFn(override_inheritance_generic_test_none_multi.A$()))();
  let B = () => (B = dart.constFn(override_inheritance_generic_test_none_multi.B$()))();
  let I = () => (I = dart.constFn(override_inheritance_generic_test_none_multi.I$()))();
  let J = () => (J = dart.constFn(override_inheritance_generic_test_none_multi.J$()))();
  let Class = () => (Class = dart.constFn(override_inheritance_generic_test_none_multi.Class$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_generic_test_none_multi.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  override_inheritance_generic_test_none_multi.A = A();
  override_inheritance_generic_test_none_multi.B$ = dart.generic(S => {
    class B extends override_inheritance_generic_test_none_multi.A {}
    return B;
  });
  override_inheritance_generic_test_none_multi.B = B();
  override_inheritance_generic_test_none_multi.I$ = dart.generic(U => {
    class I extends core.Object {}
    dart.addTypeTests(I);
    return I;
  });
  override_inheritance_generic_test_none_multi.I = I();
  override_inheritance_generic_test_none_multi.J$ = dart.generic(V => {
    class J extends core.Object {}
    dart.addTypeTests(J);
    return J;
  });
  override_inheritance_generic_test_none_multi.J = J();
  override_inheritance_generic_test_none_multi.Class$ = dart.generic(W => {
    class Class extends override_inheritance_generic_test_none_multi.B {}
    Class[dart.implements] = () => [override_inheritance_generic_test_none_multi.I, override_inheritance_generic_test_none_multi.J];
    return Class;
  });
  override_inheritance_generic_test_none_multi.Class = Class();
  override_inheritance_generic_test_none_multi.SubClass = class SubClass extends override_inheritance_generic_test_none_multi.Class {};
  dart.addSimpleTypeTests(override_inheritance_generic_test_none_multi.SubClass);
  override_inheritance_generic_test_none_multi.main = function() {
    new override_inheritance_generic_test_none_multi.SubClass();
  };
  dart.fn(override_inheritance_generic_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_generic_test_none_multi = override_inheritance_generic_test_none_multi;
});
