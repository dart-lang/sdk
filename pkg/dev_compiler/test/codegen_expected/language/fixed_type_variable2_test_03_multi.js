dart_library.library('language/fixed_type_variable2_test_03_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__fixed_type_variable2_test_03_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const fixed_type_variable2_test_03_multi = Object.create(null);
  let A = () => (A = dart.constFn(fixed_type_variable2_test_03_multi.A$()))();
  let B = () => (B = dart.constFn(fixed_type_variable2_test_03_multi.B$()))();
  let C = () => (C = dart.constFn(fixed_type_variable2_test_03_multi.C$()))();
  let AOfString = () => (AOfString = dart.constFn(fixed_type_variable2_test_03_multi.A$(core.String)))();
  let BOfint = () => (BOfint = dart.constFn(fixed_type_variable2_test_03_multi.B$(core.int)))();
  let COfString = () => (COfString = dart.constFn(fixed_type_variable2_test_03_multi.C$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  fixed_type_variable2_test_03_multi.A$ = dart.generic(T => {
    let BOfT = () => (BOfT = dart.constFn(fixed_type_variable2_test_03_multi.B$(T)))();
    class A extends core.Object {
      createB() {
        return new (BOfT())();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({createB: dart.definiteFunctionType(fixed_type_variable2_test_03_multi.B$(T), [])})
    });
    return A;
  });
  fixed_type_variable2_test_03_multi.A = A();
  fixed_type_variable2_test_03_multi.NumA = class NumA extends fixed_type_variable2_test_03_multi.A$(core.num) {};
  dart.addSimpleTypeTests(fixed_type_variable2_test_03_multi.NumA);
  fixed_type_variable2_test_03_multi.B$ = dart.generic(T => {
    class B extends core.Object {
      new() {
        this.value = null;
      }
      test(o, expect) {
        expect$.Expect.equals(expect, T.is(o));
      }
    }
    dart.addTypeTests(B);
    dart.setSignature(B, {
      methods: () => ({test: dart.definiteFunctionType(dart.void, [dart.dynamic, core.bool])})
    });
    return B;
  });
  fixed_type_variable2_test_03_multi.B = B();
  fixed_type_variable2_test_03_multi.StringB = class StringB extends fixed_type_variable2_test_03_multi.B$(core.String) {
    new() {
      super.new();
    }
  };
  dart.addSimpleTypeTests(fixed_type_variable2_test_03_multi.StringB);
  fixed_type_variable2_test_03_multi.C$ = dart.generic(T => {
    class C extends fixed_type_variable2_test_03_multi.A$(T) {}
    return C;
  });
  fixed_type_variable2_test_03_multi.C = C();
  fixed_type_variable2_test_03_multi.IntC = class IntC extends fixed_type_variable2_test_03_multi.C$(core.int) {};
  dart.addSimpleTypeTests(fixed_type_variable2_test_03_multi.IntC);
  fixed_type_variable2_test_03_multi.main = function() {
    fixed_type_variable2_test_03_multi.testB();
  };
  dart.fn(fixed_type_variable2_test_03_multi.main, VoidTovoid());
  fixed_type_variable2_test_03_multi.testA = function() {
    let instanceA = new (AOfString())();
    let instanceB = instanceA.createB();
    instanceB.test(0.5, false);
    instanceB.test(0, false);
    instanceB.test('', true);
  };
  dart.fn(fixed_type_variable2_test_03_multi.testA, VoidTovoid());
  fixed_type_variable2_test_03_multi.testNumA = function() {
    let instanceA = new fixed_type_variable2_test_03_multi.NumA();
    let instanceB = instanceA.createB();
    instanceB.test(0.5, true);
    instanceB.test(0, true);
    instanceB.test('', false);
  };
  dart.fn(fixed_type_variable2_test_03_multi.testNumA, VoidTovoid());
  fixed_type_variable2_test_03_multi.testB = function() {
    let instanceB = new (BOfint())();
    instanceB.test(0.5, false);
    instanceB.test(0, true);
    instanceB.test('', false);
  };
  dart.fn(fixed_type_variable2_test_03_multi.testB, VoidTovoid());
  fixed_type_variable2_test_03_multi.testStringB = function() {
    let instanceB = new fixed_type_variable2_test_03_multi.StringB();
    instanceB.test(0.5, false);
    instanceB.test(0, false);
    instanceB.test('', true);
  };
  dart.fn(fixed_type_variable2_test_03_multi.testStringB, VoidTovoid());
  fixed_type_variable2_test_03_multi.testC = function() {
    let instanceA = new (COfString())();
    let instanceB = instanceA.createB();
    instanceB.test(0.5, false);
    instanceB.test(0, false);
    instanceB.test('', true);
  };
  dart.fn(fixed_type_variable2_test_03_multi.testC, VoidTovoid());
  fixed_type_variable2_test_03_multi.testIntC = function() {
    let instanceA = new fixed_type_variable2_test_03_multi.IntC();
    let instanceB = instanceA.createB();
    instanceB.test(0.5, false);
    instanceB.test(0, true);
    instanceB.test('', false);
  };
  dart.fn(fixed_type_variable2_test_03_multi.testIntC, VoidTovoid());
  // Exports:
  exports.fixed_type_variable2_test_03_multi = fixed_type_variable2_test_03_multi;
});
