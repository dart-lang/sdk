dart_library.library('language/override_inheritance_generic_test_03_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_generic_test_03_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_generic_test_03_multi = Object.create(null);
  let A = () => (A = dart.constFn(override_inheritance_generic_test_03_multi.A$()))();
  let B = () => (B = dart.constFn(override_inheritance_generic_test_03_multi.B$()))();
  let I = () => (I = dart.constFn(override_inheritance_generic_test_03_multi.I$()))();
  let J = () => (J = dart.constFn(override_inheritance_generic_test_03_multi.J$()))();
  let IOfint = () => (IOfint = dart.constFn(override_inheritance_generic_test_03_multi.I$(core.int)))();
  let Class = () => (Class = dart.constFn(override_inheritance_generic_test_03_multi.Class$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_generic_test_03_multi.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  override_inheritance_generic_test_03_multi.A = A();
  override_inheritance_generic_test_03_multi.B$ = dart.generic(S => {
    class B extends override_inheritance_generic_test_03_multi.A {
      method3(s) {
        S._check(s);
        return null;
      }
    }
    dart.setSignature(B, {
      methods: () => ({method3: dart.definiteFunctionType(dart.dynamic, [S])})
    });
    return B;
  });
  override_inheritance_generic_test_03_multi.B = B();
  override_inheritance_generic_test_03_multi.I$ = dart.generic(U => {
    class I extends core.Object {
      method3(u) {
        U._check(u);
        return null;
      }
    }
    dart.addTypeTests(I);
    dart.setSignature(I, {
      methods: () => ({method3: dart.definiteFunctionType(dart.dynamic, [U])})
    });
    return I;
  });
  override_inheritance_generic_test_03_multi.I = I();
  override_inheritance_generic_test_03_multi.J$ = dart.generic(V => {
    class J extends core.Object {}
    dart.addTypeTests(J);
    return J;
  });
  override_inheritance_generic_test_03_multi.J = J();
  override_inheritance_generic_test_03_multi.Class$ = dart.generic(W => {
    class Class extends override_inheritance_generic_test_03_multi.B$(core.double) {
      method3(i) {
        return null;
      }
    }
    Class[dart.implements] = () => [IOfint(), override_inheritance_generic_test_03_multi.J];
    dart.setSignature(Class, {
      methods: () => ({method3: dart.definiteFunctionType(dart.dynamic, [core.num])})
    });
    return Class;
  });
  override_inheritance_generic_test_03_multi.Class = Class();
  override_inheritance_generic_test_03_multi.SubClass = class SubClass extends override_inheritance_generic_test_03_multi.Class {};
  dart.addSimpleTypeTests(override_inheritance_generic_test_03_multi.SubClass);
  override_inheritance_generic_test_03_multi.main = function() {
    new override_inheritance_generic_test_03_multi.SubClass();
  };
  dart.fn(override_inheritance_generic_test_03_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_generic_test_03_multi = override_inheritance_generic_test_03_multi;
});
