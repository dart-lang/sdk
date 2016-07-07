dart_library.library('language/type_argument_substitution_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_argument_substitution_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_argument_substitution_test = Object.create(null);
  let A = () => (A = dart.constFn(type_argument_substitution_test.A$()))();
  let X = () => (X = dart.constFn(type_argument_substitution_test.X$()))();
  let XOfB = () => (XOfB = dart.constFn(type_argument_substitution_test.X$(type_argument_substitution_test.B)))();
  let AOfString = () => (AOfString = dart.constFn(type_argument_substitution_test.A$(core.String)))();
  let XOfAOfString = () => (XOfAOfString = dart.constFn(type_argument_substitution_test.X$(AOfString())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_argument_substitution_test.K = class K extends core.Object {};
  type_argument_substitution_test.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  type_argument_substitution_test.A = A();
  type_argument_substitution_test.B = class B extends type_argument_substitution_test.A$(type_argument_substitution_test.K) {};
  dart.addSimpleTypeTests(type_argument_substitution_test.B);
  type_argument_substitution_test.X$ = dart.generic(T => {
    class X extends core.Object {}
    dart.addTypeTests(X);
    return X;
  });
  type_argument_substitution_test.X = X();
  type_argument_substitution_test.main = function() {
    let v = new core.DateTime.now().millisecondsSinceEpoch != 42 ? new (XOfB())() : new (XOfAOfString())();
    expect$.Expect.isFalse(XOfAOfString().is(v));
  };
  dart.fn(type_argument_substitution_test.main, VoidTodynamic());
  // Exports:
  exports.type_argument_substitution_test = type_argument_substitution_test;
});
