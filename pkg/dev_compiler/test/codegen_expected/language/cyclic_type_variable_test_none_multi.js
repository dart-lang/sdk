dart_library.library('language/cyclic_type_variable_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__cyclic_type_variable_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const cyclic_type_variable_test_none_multi = Object.create(null);
  let Base = () => (Base = dart.constFn(cyclic_type_variable_test_none_multi.Base$()))();
  let funcType = () => (funcType = dart.constFn(cyclic_type_variable_test_none_multi.funcType$()))();
  let A = () => (A = dart.constFn(cyclic_type_variable_test_none_multi.A$()))();
  let B = () => (B = dart.constFn(cyclic_type_variable_test_none_multi.B$()))();
  let C1 = () => (C1 = dart.constFn(cyclic_type_variable_test_none_multi.C1$()))();
  let C2 = () => (C2 = dart.constFn(cyclic_type_variable_test_none_multi.C2$()))();
  let D1 = () => (D1 = dart.constFn(cyclic_type_variable_test_none_multi.D1$()))();
  let D2 = () => (D2 = dart.constFn(cyclic_type_variable_test_none_multi.D2$()))();
  let E = () => (E = dart.constFn(cyclic_type_variable_test_none_multi.E$()))();
  let C1Ofint = () => (C1Ofint = dart.constFn(cyclic_type_variable_test_none_multi.C1$(core.int)))();
  let C2Ofint = () => (C2Ofint = dart.constFn(cyclic_type_variable_test_none_multi.C2$(core.int)))();
  let D1OfDerived = () => (D1OfDerived = dart.constFn(cyclic_type_variable_test_none_multi.D1$(cyclic_type_variable_test_none_multi.Derived)))();
  let D2OfDerived = () => (D2OfDerived = dart.constFn(cyclic_type_variable_test_none_multi.D2$(cyclic_type_variable_test_none_multi.Derived)))();
  let EOfDerivedFunc = () => (EOfDerivedFunc = dart.constFn(cyclic_type_variable_test_none_multi.E$(cyclic_type_variable_test_none_multi.DerivedFunc)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cyclic_type_variable_test_none_multi.Base$ = dart.generic(T => {
    class Base extends core.Object {}
    dart.addTypeTests(Base);
    return Base;
  });
  cyclic_type_variable_test_none_multi.Base = Base();
  cyclic_type_variable_test_none_multi.Derived = class Derived extends cyclic_type_variable_test_none_multi.Base {};
  dart.setBaseClass(cyclic_type_variable_test_none_multi.Derived, cyclic_type_variable_test_none_multi.Base$(cyclic_type_variable_test_none_multi.Derived));
  dart.addSimpleTypeTests(cyclic_type_variable_test_none_multi.Derived);
  cyclic_type_variable_test_none_multi.funcType$ = dart.generic(T => {
    const funcType = dart.typedef('funcType', () => dart.functionType(dart.void, [T]));
    return funcType;
  });
  cyclic_type_variable_test_none_multi.funcType = funcType();
  cyclic_type_variable_test_none_multi.DerivedFunc = class DerivedFunc extends cyclic_type_variable_test_none_multi.Base {};
  dart.setBaseClass(cyclic_type_variable_test_none_multi.DerivedFunc, cyclic_type_variable_test_none_multi.Base$(cyclic_type_variable_test_none_multi.funcType$(cyclic_type_variable_test_none_multi.DerivedFunc)));
  dart.addSimpleTypeTests(cyclic_type_variable_test_none_multi.DerivedFunc);
  cyclic_type_variable_test_none_multi.A$ = dart.generic(S => {
    class A extends core.Object {
      new() {
        this.field = null;
      }
    }
    dart.addTypeTests(A);
    return A;
  });
  cyclic_type_variable_test_none_multi.A = A();
  cyclic_type_variable_test_none_multi.B$ = dart.generic(U => {
    class B extends core.Object {
      new() {
        this.field = null;
      }
    }
    dart.addTypeTests(B);
    return B;
  });
  cyclic_type_variable_test_none_multi.B = B();
  cyclic_type_variable_test_none_multi.C1$ = dart.generic(V => {
    class C1 extends core.Object {
      new() {
        this.field = null;
      }
    }
    dart.addTypeTests(C1);
    return C1;
  });
  cyclic_type_variable_test_none_multi.C1 = C1();
  cyclic_type_variable_test_none_multi.C2$ = dart.generic(V => {
    let AOfV = () => (AOfV = dart.constFn(cyclic_type_variable_test_none_multi.A$(V)))();
    class C2 extends core.Object {
      new() {
        this.field = null;
      }
    }
    dart.addTypeTests(C2);
    C2[dart.implements] = () => [AOfV()];
    return C2;
  });
  cyclic_type_variable_test_none_multi.C2 = C2();
  cyclic_type_variable_test_none_multi.D1$ = dart.generic(W => {
    class D1 extends core.Object {
      new() {
        this.field = null;
      }
    }
    dart.addTypeTests(D1);
    return D1;
  });
  cyclic_type_variable_test_none_multi.D1 = D1();
  cyclic_type_variable_test_none_multi.D2$ = dart.generic(W => {
    let BOfW = () => (BOfW = dart.constFn(cyclic_type_variable_test_none_multi.B$(W)))();
    class D2 extends core.Object {
      new() {
        this.field = null;
      }
    }
    dart.addTypeTests(D2);
    D2[dart.implements] = () => [BOfW()];
    return D2;
  });
  cyclic_type_variable_test_none_multi.D2 = D2();
  cyclic_type_variable_test_none_multi.E$ = dart.generic(X => {
    class E extends core.Object {
      new() {
        this.field = null;
      }
    }
    dart.addTypeTests(E);
    return E;
  });
  cyclic_type_variable_test_none_multi.E = E();
  cyclic_type_variable_test_none_multi.main = function() {
    new (C1Ofint())();
    new (C2Ofint())();
    new (D1OfDerived())();
    new (D2OfDerived())();
    new (EOfDerivedFunc())();
    let val = null;
  };
  dart.fn(cyclic_type_variable_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.cyclic_type_variable_test_none_multi = cyclic_type_variable_test_none_multi;
});
