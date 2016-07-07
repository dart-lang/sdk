dart_library.library('language/generic_native_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_native_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_native_test = Object.create(null);
  let A = () => (A = dart.constFn(generic_native_test.A$()))();
  let ListOfB = () => (ListOfB = dart.constFn(core.List$(generic_native_test.B)))();
  let IterableOfB = () => (IterableOfB = dart.constFn(core.Iterable$(generic_native_test.B)))();
  let AOfIterableOfB = () => (AOfIterableOfB = dart.constFn(generic_native_test.A$(IterableOfB())))();
  let IterableOfC = () => (IterableOfC = dart.constFn(core.Iterable$(generic_native_test.C)))();
  let AOfIterableOfC = () => (AOfIterableOfC = dart.constFn(generic_native_test.A$(IterableOfC())))();
  let AOfPattern = () => (AOfPattern = dart.constFn(generic_native_test.A$(core.Pattern)))();
  let ComparableOfString = () => (ComparableOfString = dart.constFn(core.Comparable$(core.String)))();
  let AOfComparableOfString = () => (AOfComparableOfString = dart.constFn(generic_native_test.A$(ComparableOfString())))();
  let ComparableOfC = () => (ComparableOfC = dart.constFn(core.Comparable$(generic_native_test.C)))();
  let AOfComparableOfC = () => (AOfComparableOfC = dart.constFn(generic_native_test.A$(ComparableOfC())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_native_test.A$ = dart.generic(T => {
    class A extends core.Object {
      foo(o) {
        return T.is(o);
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
    });
    return A;
  });
  generic_native_test.A = A();
  generic_native_test.B = class B extends core.Object {};
  generic_native_test.C = class C extends core.Object {};
  generic_native_test.main = function() {
    expect$.Expect.isTrue(new (AOfIterableOfB())().foo(ListOfB().new()));
    expect$.Expect.isFalse(new (AOfIterableOfC())().foo(ListOfB().new()));
    expect$.Expect.isTrue(new (AOfPattern())().foo('hest'));
    expect$.Expect.isTrue(new (AOfComparableOfString())().foo('hest'));
    expect$.Expect.isFalse(new (AOfComparableOfC())().foo('hest'));
  };
  dart.fn(generic_native_test.main, VoidTodynamic());
  // Exports:
  exports.generic_native_test = generic_native_test;
});
