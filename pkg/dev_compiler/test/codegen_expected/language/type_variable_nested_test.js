dart_library.library('language/type_variable_nested_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_variable_nested_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_variable_nested_test = Object.create(null);
  let A = () => (A = dart.constFn(type_variable_nested_test.A$()))();
  let B = () => (B = dart.constFn(type_variable_nested_test.B$()))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let ListOfA = () => (ListOfA = dart.constFn(core.List$(type_variable_nested_test.A)))();
  let AOfint = () => (AOfint = dart.constFn(type_variable_nested_test.A$(core.int)))();
  let ListOfAOfint = () => (ListOfAOfint = dart.constFn(core.List$(AOfint())))();
  let BOfString = () => (BOfString = dart.constFn(type_variable_nested_test.B$(core.String)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let AOfString = () => (AOfString = dart.constFn(type_variable_nested_test.A$(core.String)))();
  let ListOfAOfString = () => (ListOfAOfString = dart.constFn(core.List$(AOfString())))();
  let AOfObject = () => (AOfObject = dart.constFn(type_variable_nested_test.A$(core.Object)))();
  let ListOfAOfObject = () => (ListOfAOfObject = dart.constFn(core.List$(AOfObject())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_variable_nested_test.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  type_variable_nested_test.A = A();
  const _copy = Symbol('_copy');
  type_variable_nested_test.B$ = dart.generic(T => {
    let AOfT = () => (AOfT = dart.constFn(type_variable_nested_test.A$(T)))();
    let ListOfAOfT = () => (ListOfAOfT = dart.constFn(core.List$(AOfT())))();
    class B extends core.Object {
      new() {
        this[_copy] = null;
        this[_copy] = ListOfAOfT().new();
      }
    }
    dart.addTypeTests(B);
    dart.setSignature(B, {
      constructors: () => ({new: dart.definiteFunctionType(type_variable_nested_test.B$(T), [])})
    });
    return B;
  });
  type_variable_nested_test.B = B();
  type_variable_nested_test.main = function() {
    let a = new type_variable_nested_test.B();
    expect$.Expect.isFalse(ListOfint().is(a[_copy]));
    expect$.Expect.isTrue(ListOfA().is(a[_copy]));
    expect$.Expect.isTrue(ListOfAOfint().is(a[_copy]));
    a = new (BOfString())();
    expect$.Expect.isFalse(ListOfString().is(a[_copy]));
    expect$.Expect.isTrue(ListOfA().is(a[_copy]));
    expect$.Expect.isTrue(ListOfAOfString().is(a[_copy]));
    expect$.Expect.isTrue(ListOfAOfObject().is(a[_copy]));
    expect$.Expect.isFalse(ListOfAOfint().is(a[_copy]));
  };
  dart.fn(type_variable_nested_test.main, VoidTodynamic());
  // Exports:
  exports.type_variable_nested_test = type_variable_nested_test;
});
