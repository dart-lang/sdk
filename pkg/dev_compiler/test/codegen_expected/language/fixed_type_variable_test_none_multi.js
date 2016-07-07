dart_library.library('language/fixed_type_variable_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__fixed_type_variable_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const fixed_type_variable_test_none_multi = Object.create(null);
  let A = () => (A = dart.constFn(fixed_type_variable_test_none_multi.A$()))();
  let B = () => (B = dart.constFn(fixed_type_variable_test_none_multi.B$()))();
  let C = () => (C = dart.constFn(fixed_type_variable_test_none_multi.C$()))();
  let AOfString = () => (AOfString = dart.constFn(fixed_type_variable_test_none_multi.A$(core.String)))();
  let BOfint = () => (BOfint = dart.constFn(fixed_type_variable_test_none_multi.B$(core.int)))();
  let COfString = () => (COfString = dart.constFn(fixed_type_variable_test_none_multi.C$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  fixed_type_variable_test_none_multi.A$ = dart.generic(T => {
    let BOfT = () => (BOfT = dart.constFn(fixed_type_variable_test_none_multi.B$(T)))();
    class A extends core.Object {
      createB() {
        return new (BOfT())();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({createB: dart.definiteFunctionType(fixed_type_variable_test_none_multi.B$(T), [])})
    });
    return A;
  });
  fixed_type_variable_test_none_multi.A = A();
  fixed_type_variable_test_none_multi.NumA = class NumA extends fixed_type_variable_test_none_multi.A$(core.num) {};
  dart.addSimpleTypeTests(fixed_type_variable_test_none_multi.NumA);
  fixed_type_variable_test_none_multi.B$ = dart.generic(T => {
    class B extends core.Object {
      new() {
        this.value = null;
      }
      test(type, expect) {
        expect$.Expect.equals(expect, dart.equals(dart.wrapType(T), type));
      }
    }
    dart.addTypeTests(B);
    dart.setSignature(B, {
      methods: () => ({test: dart.definiteFunctionType(dart.void, [dart.dynamic, core.bool])})
    });
    return B;
  });
  fixed_type_variable_test_none_multi.B = B();
  fixed_type_variable_test_none_multi.StringB = class StringB extends fixed_type_variable_test_none_multi.B$(core.String) {
    new() {
      super.new();
    }
  };
  dart.addSimpleTypeTests(fixed_type_variable_test_none_multi.StringB);
  fixed_type_variable_test_none_multi.C$ = dart.generic(T => {
    class C extends fixed_type_variable_test_none_multi.A$(T) {}
    return C;
  });
  fixed_type_variable_test_none_multi.C = C();
  fixed_type_variable_test_none_multi.IntC = class IntC extends fixed_type_variable_test_none_multi.C$(core.int) {};
  dart.addSimpleTypeTests(fixed_type_variable_test_none_multi.IntC);
  fixed_type_variable_test_none_multi.main = function() {
  };
  dart.fn(fixed_type_variable_test_none_multi.main, VoidTovoid());
  fixed_type_variable_test_none_multi.testA = function() {
    let instanceA = new (AOfString())();
    let instanceB = instanceA.createB();
    instanceB.test(dart.wrapType(core.num), false);
    instanceB.test(dart.wrapType(core.int), false);
    instanceB.test(dart.wrapType(core.String), true);
  };
  dart.fn(fixed_type_variable_test_none_multi.testA, VoidTovoid());
  fixed_type_variable_test_none_multi.testNumA = function() {
    let instanceA = new fixed_type_variable_test_none_multi.NumA();
    let instanceB = instanceA.createB();
    instanceB.test(dart.wrapType(core.num), true);
    instanceB.test(dart.wrapType(core.int), false);
    instanceB.test(dart.wrapType(core.String), false);
  };
  dart.fn(fixed_type_variable_test_none_multi.testNumA, VoidTovoid());
  fixed_type_variable_test_none_multi.testB = function() {
    let instanceB = new (BOfint())();
    instanceB.test(dart.wrapType(core.num), false);
    instanceB.test(dart.wrapType(core.int), true);
    instanceB.test(dart.wrapType(core.String), false);
  };
  dart.fn(fixed_type_variable_test_none_multi.testB, VoidTovoid());
  fixed_type_variable_test_none_multi.testStringB = function() {
    let instanceB = new fixed_type_variable_test_none_multi.StringB();
    instanceB.test(dart.wrapType(core.num), false);
    instanceB.test(dart.wrapType(core.int), false);
    instanceB.test(dart.wrapType(core.String), true);
  };
  dart.fn(fixed_type_variable_test_none_multi.testStringB, VoidTovoid());
  fixed_type_variable_test_none_multi.testC = function() {
    let instanceA = new (COfString())();
    let instanceB = instanceA.createB();
    instanceB.test(dart.wrapType(core.num), false);
    instanceB.test(dart.wrapType(core.int), false);
    instanceB.test(dart.wrapType(core.String), true);
  };
  dart.fn(fixed_type_variable_test_none_multi.testC, VoidTovoid());
  fixed_type_variable_test_none_multi.testIntC = function() {
    let instanceA = new fixed_type_variable_test_none_multi.IntC();
    let instanceB = instanceA.createB();
    instanceB.test(dart.wrapType(core.num), false);
    instanceB.test(dart.wrapType(core.int), true);
    instanceB.test(dart.wrapType(core.String), false);
  };
  dart.fn(fixed_type_variable_test_none_multi.testIntC, VoidTovoid());
  // Exports:
  exports.fixed_type_variable_test_none_multi = fixed_type_variable_test_none_multi;
});
