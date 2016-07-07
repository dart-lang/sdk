dart_library.library('language/cyclic_type_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cyclic_type_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cyclic_type_test_01_multi = Object.create(null);
  let Base = () => (Base = dart.constFn(cyclic_type_test_01_multi.Base$()))();
  let Derived = () => (Derived = dart.constFn(cyclic_type_test_01_multi.Derived$()))();
  let DerivedOfbool = () => (DerivedOfbool = dart.constFn(cyclic_type_test_01_multi.Derived$(core.bool)))();
  let DerivedOfDerived = () => (DerivedOfDerived = dart.constFn(cyclic_type_test_01_multi.Derived$(cyclic_type_test_01_multi.Derived)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cyclic_type_test_01_multi.Base$ = dart.generic(T => {
    class Base extends core.Object {
      get t() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(Base);
    return Base;
  });
  cyclic_type_test_01_multi.Base = Base();
  cyclic_type_test_01_multi.Derived$ = dart.generic(T => {
    class Derived extends cyclic_type_test_01_multi.Base {}
    dart.setBaseClass(Derived, cyclic_type_test_01_multi.Base$(cyclic_type_test_01_multi.Derived$(cyclic_type_test_01_multi.Derived$(core.int))));
    return Derived;
  });
  cyclic_type_test_01_multi.Derived = Derived();
  cyclic_type_test_01_multi.main = function() {
    let d = null;
    d = new cyclic_type_test_01_multi.Derived();
    expect$.Expect.equals("Derived<Derived<int>>", dart.toString(dart.dload(d, 't')));
    d = new (DerivedOfbool())();
    expect$.Expect.equals("Derived<Derived<int>>", dart.toString(dart.dload(d, 't')));
    d = new (DerivedOfDerived())();
    expect$.Expect.equals("Derived<Derived<int>>", dart.toString(dart.dload(d, 't')));
  };
  dart.fn(cyclic_type_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.cyclic_type_test_01_multi = cyclic_type_test_01_multi;
});
