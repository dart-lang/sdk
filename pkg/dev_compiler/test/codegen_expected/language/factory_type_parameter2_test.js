dart_library.library('language/factory_type_parameter2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__factory_type_parameter2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const factory_type_parameter2_test = Object.create(null);
  let I = () => (I = dart.constFn(factory_type_parameter2_test.I$()))();
  let C = () => (C = dart.constFn(factory_type_parameter2_test.C$()))();
  let IOfD = () => (IOfD = dart.constFn(factory_type_parameter2_test.I$(factory_type_parameter2_test.D)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  factory_type_parameter2_test.p = null;
  factory_type_parameter2_test.done = false;
  factory_type_parameter2_test.D = class D extends core.Object {};
  factory_type_parameter2_test.I$ = dart.generic(T => {
    let COfT = () => (COfT = dart.constFn(factory_type_parameter2_test.C$(T)))();
    class I extends core.Object {
      static name() {
        return new (COfT()).name();
      }
    }
    dart.addTypeTests(I);
    dart.setSignature(I, {
      constructors: () => ({name: dart.definiteFunctionType(factory_type_parameter2_test.I$(T), [])})
    });
    return I;
  });
  factory_type_parameter2_test.I = I();
  factory_type_parameter2_test.C$ = dart.generic(T => {
    let IOfT = () => (IOfT = dart.constFn(factory_type_parameter2_test.I$(T)))();
    class C extends core.Object {
      name() {
        expect$.Expect.isTrue(T.is(factory_type_parameter2_test.p));
        factory_type_parameter2_test.done = true;
      }
    }
    dart.addTypeTests(C);
    dart.defineNamedConstructor(C, 'name');
    C[dart.implements] = () => [IOfT()];
    dart.setSignature(C, {
      constructors: () => ({name: dart.definiteFunctionType(factory_type_parameter2_test.C$(T), [])})
    });
    return C;
  });
  factory_type_parameter2_test.C = C();
  factory_type_parameter2_test.main = function() {
    factory_type_parameter2_test.p = new factory_type_parameter2_test.D();
    IOfD().name();
    expect$.Expect.equals(true, factory_type_parameter2_test.done);
  };
  dart.fn(factory_type_parameter2_test.main, VoidTodynamic());
  // Exports:
  exports.factory_type_parameter2_test = factory_type_parameter2_test;
});
