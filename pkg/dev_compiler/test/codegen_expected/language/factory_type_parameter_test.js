dart_library.library('language/factory_type_parameter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__factory_type_parameter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const factory_type_parameter_test = Object.create(null);
  let A = () => (A = dart.constFn(factory_type_parameter_test.A$()))();
  let B = () => (B = dart.constFn(factory_type_parameter_test.B$()))();
  let AOfList = () => (AOfList = dart.constFn(factory_type_parameter_test.A$(core.List)))();
  let BOfList = () => (BOfList = dart.constFn(factory_type_parameter_test.B$(core.List)))();
  let AOfSet = () => (AOfSet = dart.constFn(factory_type_parameter_test.A$(core.Set)))();
  let BOfSet = () => (BOfSet = dart.constFn(factory_type_parameter_test.B$(core.Set)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  factory_type_parameter_test.A$ = dart.generic(T => {
    let BOfT = () => (BOfT = dart.constFn(factory_type_parameter_test.B$(T)))();
    let AOfT = () => (AOfT = dart.constFn(factory_type_parameter_test.A$(T)))();
    class A extends core.Object {
      static factory() {
        return new (BOfT())();
      }
      new() {
      }
      build() {
        return new (AOfT())();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({
        factory: dart.definiteFunctionType(factory_type_parameter_test.A$(T), []),
        new: dart.definiteFunctionType(factory_type_parameter_test.A$(T), [])
      }),
      methods: () => ({build: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return A;
  });
  factory_type_parameter_test.A = A();
  factory_type_parameter_test.B$ = dart.generic(T => {
    let BOfT = () => (BOfT = dart.constFn(factory_type_parameter_test.B$(T)))();
    class B extends factory_type_parameter_test.A$(T) {
      new() {
        super.new();
      }
      build() {
        return new (BOfT())();
      }
    }
    dart.setSignature(B, {
      constructors: () => ({new: dart.definiteFunctionType(factory_type_parameter_test.B$(T), [])})
    });
    return B;
  });
  factory_type_parameter_test.B = B();
  factory_type_parameter_test.main = function() {
    expect$.Expect.isTrue(AOfList().is(new (AOfList())()));
    expect$.Expect.isTrue(BOfList().is(AOfList().factory()));
    expect$.Expect.isFalse(AOfSet().is(new (AOfList())()));
    expect$.Expect.isFalse(BOfSet().is(AOfList().factory()));
    expect$.Expect.isTrue(AOfList().is(new (AOfList())().build()));
    expect$.Expect.isFalse(AOfSet().is(new (AOfList())().build()));
    expect$.Expect.isTrue(BOfList().is(AOfList().factory().build()));
    expect$.Expect.isFalse(BOfSet().is(AOfList().factory().build()));
    expect$.Expect.isTrue(BOfList().is(new (BOfList())().build()));
    expect$.Expect.isFalse(BOfSet().is(new (BOfList())().build()));
  };
  dart.fn(factory_type_parameter_test.main, VoidTodynamic());
  // Exports:
  exports.factory_type_parameter_test = factory_type_parameter_test;
});
