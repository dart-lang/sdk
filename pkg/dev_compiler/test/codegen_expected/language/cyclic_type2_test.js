dart_library.library('language/cyclic_type2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cyclic_type2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cyclic_type2_test = Object.create(null);
  let Base = () => (Base = dart.constFn(cyclic_type2_test.Base$()))();
  let Derived1 = () => (Derived1 = dart.constFn(cyclic_type2_test.Derived1$()))();
  let Derived2 = () => (Derived2 = dart.constFn(cyclic_type2_test.Derived2$()))();
  let Derived1OfDerived1$Derived2 = () => (Derived1OfDerived1$Derived2 = dart.constFn(cyclic_type2_test.Derived1$(cyclic_type2_test.Derived1, cyclic_type2_test.Derived2)))();
  let Derived1OfDerived1$Derived1 = () => (Derived1OfDerived1$Derived1 = dart.constFn(cyclic_type2_test.Derived1$(cyclic_type2_test.Derived1, cyclic_type2_test.Derived1)))();
  let Derived2OfDerived2$Derived1 = () => (Derived2OfDerived2$Derived1 = dart.constFn(cyclic_type2_test.Derived2$(cyclic_type2_test.Derived2, cyclic_type2_test.Derived1)))();
  let Derived1OfDerived2OfDerived2$Derived1$Derived2 = () => (Derived1OfDerived2OfDerived2$Derived1$Derived2 = dart.constFn(cyclic_type2_test.Derived1$(Derived2OfDerived2$Derived1(), cyclic_type2_test.Derived2)))();
  let BaseOfDerived1OfDerived1$Derived2$Derived1OfDerived2OfDerived2$Derived1$Derived2 = () => (BaseOfDerived1OfDerived1$Derived2$Derived1OfDerived2OfDerived2$Derived1$Derived2 = dart.constFn(cyclic_type2_test.Base$(Derived1OfDerived1$Derived2(), Derived1OfDerived2OfDerived2$Derived1$Derived2())))();
  let Derived2OfDerived2$Derived2 = () => (Derived2OfDerived2$Derived2 = dart.constFn(cyclic_type2_test.Derived2$(cyclic_type2_test.Derived2, cyclic_type2_test.Derived2)))();
  let Derived1OfDerived2OfDerived2$Derived2$Derived2 = () => (Derived1OfDerived2OfDerived2$Derived2$Derived2 = dart.constFn(cyclic_type2_test.Derived1$(Derived2OfDerived2$Derived2(), cyclic_type2_test.Derived2)))();
  let BaseOfDerived1OfDerived1$Derived2$Derived1OfDerived2OfDerived2$Derived2$Derived2 = () => (BaseOfDerived1OfDerived1$Derived2$Derived1OfDerived2OfDerived2$Derived2$Derived2 = dart.constFn(cyclic_type2_test.Base$(Derived1OfDerived1$Derived2(), Derived1OfDerived2OfDerived2$Derived2$Derived2())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cyclic_type2_test.Base$ = dart.generic((U, V) => {
    class Base extends core.Object {
      get u() {
        return dart.wrapType(U);
      }
      get v() {
        return dart.wrapType(V);
      }
    }
    dart.addTypeTests(Base);
    return Base;
  });
  cyclic_type2_test.Base = Base();
  cyclic_type2_test.Derived1$ = dart.generic((U, V) => {
    class Derived1 extends cyclic_type2_test.Base {}
    dart.setBaseClass(Derived1, cyclic_type2_test.Base$(Derived1, cyclic_type2_test.Derived1$(cyclic_type2_test.Derived2$(V, U), cyclic_type2_test.Derived2)));
    return Derived1;
  });
  cyclic_type2_test.Derived1 = Derived1();
  cyclic_type2_test.Derived2$ = dart.generic((U, V) => {
    class Derived2 extends cyclic_type2_test.Base {}
    dart.setBaseClass(Derived2, cyclic_type2_test.Base$(Derived2, cyclic_type2_test.Derived2$(cyclic_type2_test.Derived1$(V, U), cyclic_type2_test.Derived1)));
    return Derived2;
  });
  cyclic_type2_test.Derived2 = Derived2();
  cyclic_type2_test.main = function() {
    let d = new (Derived1OfDerived1$Derived2())();
    expect$.Expect.equals("Derived1<Derived1, Derived2>", dart.toString(d.u));
    expect$.Expect.equals("Derived1<Derived2<Derived2, Derived1>, Derived2>", dart.toString(d.v));
    expect$.Expect.isTrue(Derived1OfDerived1$Derived2().is(d));
    expect$.Expect.isFalse(Derived1OfDerived1$Derived1().is(d));
    expect$.Expect.isTrue(BaseOfDerived1OfDerived1$Derived2$Derived1OfDerived2OfDerived2$Derived1$Derived2().is(d));
    expect$.Expect.isFalse(BaseOfDerived1OfDerived1$Derived2$Derived1OfDerived2OfDerived2$Derived2$Derived2().is(d));
  };
  dart.fn(cyclic_type2_test.main, VoidTodynamic());
  // Exports:
  exports.cyclic_type2_test = cyclic_type2_test;
});
