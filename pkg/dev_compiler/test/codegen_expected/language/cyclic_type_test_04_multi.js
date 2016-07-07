dart_library.library('language/cyclic_type_test_04_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cyclic_type_test_04_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cyclic_type_test_04_multi = Object.create(null);
  let Base = () => (Base = dart.constFn(cyclic_type_test_04_multi.Base$()))();
  let Derived2 = () => (Derived2 = dart.constFn(cyclic_type_test_04_multi.Derived2$()))();
  let Derived1 = () => (Derived1 = dart.constFn(cyclic_type_test_04_multi.Derived1$()))();
  let Derived1Ofint = () => (Derived1Ofint = dart.constFn(cyclic_type_test_04_multi.Derived1$(core.int)))();
  let Derived2OfDerived1Ofint = () => (Derived2OfDerived1Ofint = dart.constFn(cyclic_type_test_04_multi.Derived2$(Derived1Ofint())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cyclic_type_test_04_multi.Base$ = dart.generic(T => {
    class Base extends core.Object {
      get t() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(Base);
    return Base;
  });
  cyclic_type_test_04_multi.Base = Base();
  cyclic_type_test_04_multi.Derived2$ = dart.generic(V => {
    class Derived2 extends cyclic_type_test_04_multi.Base {}
    dart.setBaseClass(Derived2, cyclic_type_test_04_multi.Base$(cyclic_type_test_04_multi.Derived1$(Derived2)));
    return Derived2;
  });
  cyclic_type_test_04_multi.Derived2 = Derived2();
  cyclic_type_test_04_multi.Derived1$ = dart.generic(U => {
    class Derived1 extends cyclic_type_test_04_multi.Base$(cyclic_type_test_04_multi.Derived2$(U)) {}
    return Derived1;
  });
  cyclic_type_test_04_multi.Derived1 = Derived1();
  cyclic_type_test_04_multi.main = function() {
    let d = null;
    d = new cyclic_type_test_04_multi.Derived1();
    expect$.Expect.equals("Derived2", dart.toString(dart.dload(d, 't')));
    d = new cyclic_type_test_04_multi.Derived2();
    expect$.Expect.equals("Derived1<Derived2>", dart.toString(dart.dload(d, 't')));
    d = new (Derived2OfDerived1Ofint())();
    expect$.Expect.equals("Derived1<Derived2<Derived1<int>>>", dart.toString(dart.dload(d, 't')));
  };
  dart.fn(cyclic_type_test_04_multi.main, VoidTodynamic());
  // Exports:
  exports.cyclic_type_test_04_multi = cyclic_type_test_04_multi;
});
