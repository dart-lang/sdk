dart_library.library('language/generic_parameterized_extends_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_parameterized_extends_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_parameterized_extends_test = Object.create(null);
  let A = () => (A = dart.constFn(generic_parameterized_extends_test.A$()))();
  let B = () => (B = dart.constFn(generic_parameterized_extends_test.B$()))();
  let C = () => (C = dart.constFn(generic_parameterized_extends_test.C$()))();
  let AOfString = () => (AOfString = dart.constFn(generic_parameterized_extends_test.A$(core.String)))();
  let BOfString$AOfString = () => (BOfString$AOfString = dart.constFn(generic_parameterized_extends_test.B$(core.String, AOfString())))();
  let COfAOfString$String = () => (COfAOfString$String = dart.constFn(generic_parameterized_extends_test.C$(AOfString(), core.String)))();
  let AOfObject = () => (AOfObject = dart.constFn(generic_parameterized_extends_test.A$(core.Object)))();
  let AOfint = () => (AOfint = dart.constFn(generic_parameterized_extends_test.A$(core.int)))();
  let BOfObject$AOfObject = () => (BOfObject$AOfObject = dart.constFn(generic_parameterized_extends_test.B$(core.Object, AOfObject())))();
  let BOfint$AOfint = () => (BOfint$AOfint = dart.constFn(generic_parameterized_extends_test.B$(core.int, AOfint())))();
  let COfAOfObject$Object = () => (COfAOfObject$Object = dart.constFn(generic_parameterized_extends_test.C$(AOfObject(), core.Object)))();
  let COfAOfint$int = () => (COfAOfint$int = dart.constFn(generic_parameterized_extends_test.C$(AOfint(), core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_parameterized_extends_test.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  generic_parameterized_extends_test.A = A();
  generic_parameterized_extends_test.B$ = dart.generic((T1, T2) => {
    class B extends core.Object {}
    dart.addTypeTests(B);
    return B;
  });
  generic_parameterized_extends_test.B = B();
  generic_parameterized_extends_test.C$ = dart.generic((T1, T2) => {
    class C extends core.Object {}
    dart.addTypeTests(C);
    return C;
  });
  generic_parameterized_extends_test.C = C();
  generic_parameterized_extends_test.main = function() {
    let a = new (AOfString())();
    let b = new (BOfString$AOfString())();
    let c = new (COfAOfString$String())();
    expect$.Expect.isTrue(core.Object.is(a));
    expect$.Expect.isTrue(AOfObject().is(a));
    expect$.Expect.isTrue(AOfString().is(a));
    expect$.Expect.isTrue(!AOfint().is(a));
    expect$.Expect.isTrue(core.Object.is(b));
    expect$.Expect.isTrue(BOfObject$AOfObject().is(b));
    expect$.Expect.isTrue(BOfString$AOfString().is(b));
    expect$.Expect.isTrue(!BOfint$AOfint().is(b));
    expect$.Expect.isTrue(core.Object.is(c));
    expect$.Expect.isTrue(COfAOfObject$Object().is(c));
    expect$.Expect.isTrue(COfAOfString$String().is(c));
    expect$.Expect.isTrue(!COfAOfint$int().is(c));
  };
  dart.fn(generic_parameterized_extends_test.main, VoidTodynamic());
  // Exports:
  exports.generic_parameterized_extends_test = generic_parameterized_extends_test;
});
