dart_library.library('language/is_operator_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__is_operator_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const is_operator_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  is_operator_test.I = class I extends core.Object {};
  is_operator_test.AI = class AI extends core.Object {};
  is_operator_test.AI[dart.implements] = () => [is_operator_test.I];
  is_operator_test.A = class A extends core.Object {
    new() {
    }
  };
  is_operator_test.A[dart.implements] = () => [is_operator_test.AI];
  dart.setSignature(is_operator_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(is_operator_test.A, [])})
  });
  is_operator_test.B = class B extends core.Object {
    new() {
    }
  };
  is_operator_test.B[dart.implements] = () => [is_operator_test.I];
  dart.setSignature(is_operator_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(is_operator_test.B, [])})
  });
  is_operator_test.C = class C extends is_operator_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(is_operator_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(is_operator_test.C, [])})
  });
  is_operator_test.IsOperatorTest = class IsOperatorTest extends core.Object {
    static testMain() {
      let a = new is_operator_test.A();
      let b = new is_operator_test.B();
      let c = new is_operator_test.C();
      let n = null;
      expect$.Expect.equals(true, is_operator_test.A.is(a));
      expect$.Expect.equals(false, !is_operator_test.A.is(a));
      expect$.Expect.equals(true, is_operator_test.B.is(b));
      expect$.Expect.equals(false, !is_operator_test.B.is(b));
      expect$.Expect.equals(true, is_operator_test.C.is(c));
      expect$.Expect.equals(false, !is_operator_test.C.is(c));
      expect$.Expect.equals(true, is_operator_test.A.is(c));
      expect$.Expect.equals(false, !is_operator_test.A.is(c));
      expect$.Expect.equals(true, is_operator_test.AI.is(a));
      expect$.Expect.equals(false, !is_operator_test.AI.is(a));
      expect$.Expect.equals(true, is_operator_test.I.is(a));
      expect$.Expect.equals(false, !is_operator_test.I.is(a));
      expect$.Expect.equals(false, is_operator_test.AI.is(b));
      expect$.Expect.equals(true, !is_operator_test.AI.is(b));
      expect$.Expect.equals(true, is_operator_test.I.is(b));
      expect$.Expect.equals(false, !is_operator_test.I.is(b));
      expect$.Expect.equals(true, is_operator_test.AI.is(c));
      expect$.Expect.equals(false, !is_operator_test.AI.is(c));
      expect$.Expect.equals(true, is_operator_test.I.is(c));
      expect$.Expect.equals(false, !is_operator_test.I.is(c));
      expect$.Expect.equals(false, is_operator_test.AI.is(n));
      expect$.Expect.equals(true, !is_operator_test.AI.is(n));
      expect$.Expect.equals(false, is_operator_test.I.is(n));
      expect$.Expect.equals(true, !is_operator_test.I.is(n));
      expect$.Expect.equals(false, is_operator_test.B.is(a));
      expect$.Expect.equals(true, !is_operator_test.B.is(a));
      expect$.Expect.equals(false, is_operator_test.C.is(a));
      expect$.Expect.equals(true, !is_operator_test.C.is(a));
      expect$.Expect.equals(false, is_operator_test.A.is(b));
      expect$.Expect.equals(true, !is_operator_test.A.is(b));
      expect$.Expect.equals(false, is_operator_test.C.is(b));
      expect$.Expect.equals(true, !is_operator_test.C.is(b));
      expect$.Expect.equals(false, is_operator_test.B.is(c));
      expect$.Expect.equals(true, !is_operator_test.B.is(c));
      expect$.Expect.equals(false, is_operator_test.A.is(n));
      expect$.Expect.equals(true, !is_operator_test.A.is(n));
      expect$.Expect.equals(false, is_operator_test.A.is(null));
      expect$.Expect.equals(false, is_operator_test.B.is(null));
      expect$.Expect.equals(false, is_operator_test.C.is(null));
      expect$.Expect.equals(false, is_operator_test.AI.is(null));
      expect$.Expect.equals(false, is_operator_test.I.is(null));
      expect$.Expect.equals(true, !is_operator_test.A.is(null));
      expect$.Expect.equals(true, !is_operator_test.B.is(null));
      expect$.Expect.equals(true, !is_operator_test.C.is(null));
      expect$.Expect.equals(true, !is_operator_test.AI.is(null));
      expect$.Expect.equals(true, !is_operator_test.I.is(null));
    }
  };
  dart.setSignature(is_operator_test.IsOperatorTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  is_operator_test.main = function() {
    is_operator_test.IsOperatorTest.testMain();
  };
  dart.fn(is_operator_test.main, VoidTodynamic());
  // Exports:
  exports.is_operator_test = is_operator_test;
});
