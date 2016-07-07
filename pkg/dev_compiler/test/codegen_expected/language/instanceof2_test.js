dart_library.library('language/instanceof2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__instanceof2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const instanceof2_test = Object.create(null);
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let ListOfnum = () => (ListOfnum = dart.constFn(core.List$(core.num)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  instanceof2_test.I = class I extends core.Object {};
  instanceof2_test.AI = class AI extends core.Object {};
  instanceof2_test.AI[dart.implements] = () => [instanceof2_test.I];
  instanceof2_test.A = class A extends core.Object {
    new() {
    }
  };
  instanceof2_test.A[dart.implements] = () => [instanceof2_test.AI];
  dart.setSignature(instanceof2_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(instanceof2_test.A, [])})
  });
  instanceof2_test.B = class B extends core.Object {
    new() {
    }
  };
  instanceof2_test.B[dart.implements] = () => [instanceof2_test.I];
  dart.setSignature(instanceof2_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(instanceof2_test.B, [])})
  });
  instanceof2_test.C = class C extends instanceof2_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(instanceof2_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(instanceof2_test.C, [])})
  });
  instanceof2_test.InstanceofTest = class InstanceofTest extends core.Object {
    static testMain() {
      let a = new instanceof2_test.A();
      let b = new instanceof2_test.B();
      let c = new instanceof2_test.C();
      let n = null;
      expect$.Expect.equals(true, instanceof2_test.A.is(a));
      expect$.Expect.equals(true, instanceof2_test.B.is(b));
      expect$.Expect.equals(true, instanceof2_test.C.is(c));
      expect$.Expect.equals(true, instanceof2_test.A.is(c));
      expect$.Expect.equals(true, instanceof2_test.AI.is(a));
      expect$.Expect.equals(true, instanceof2_test.I.is(a));
      expect$.Expect.equals(false, instanceof2_test.AI.is(b));
      expect$.Expect.equals(true, instanceof2_test.I.is(b));
      expect$.Expect.equals(true, instanceof2_test.AI.is(c));
      expect$.Expect.equals(true, instanceof2_test.I.is(c));
      expect$.Expect.equals(false, instanceof2_test.AI.is(n));
      expect$.Expect.equals(false, instanceof2_test.I.is(n));
      expect$.Expect.equals(false, instanceof2_test.B.is(a));
      expect$.Expect.equals(false, instanceof2_test.C.is(a));
      expect$.Expect.equals(false, instanceof2_test.A.is(b));
      expect$.Expect.equals(false, instanceof2_test.C.is(b));
      expect$.Expect.equals(false, instanceof2_test.B.is(c));
      expect$.Expect.equals(false, instanceof2_test.A.is(n));
      expect$.Expect.equals(false, instanceof2_test.A.is(null));
      expect$.Expect.equals(false, instanceof2_test.B.is(null));
      expect$.Expect.equals(false, instanceof2_test.C.is(null));
      expect$.Expect.equals(false, instanceof2_test.AI.is(null));
      expect$.Expect.equals(false, instanceof2_test.I.is(null));
      {
        let a = core.List.new(5);
        expect$.Expect.equals(true, core.List.is(a));
        expect$.Expect.equals(true, ListOfObject().is(a));
        expect$.Expect.equals(true, ListOfint().is(a));
        expect$.Expect.equals(true, ListOfnum().is(a));
        expect$.Expect.equals(true, ListOfString().is(a));
      }
      {
        let a = ListOfObject().new(5);
        expect$.Expect.equals(true, core.List.is(a));
        expect$.Expect.equals(true, ListOfObject().is(a));
        expect$.Expect.equals(false, ListOfint().is(a));
        expect$.Expect.equals(false, ListOfnum().is(a));
        expect$.Expect.equals(false, ListOfString().is(a));
      }
      {
        let a = ListOfint().new(5);
        expect$.Expect.equals(true, core.List.is(a));
        expect$.Expect.equals(true, ListOfObject().is(a));
        expect$.Expect.equals(true, ListOfint().is(a));
        expect$.Expect.equals(true, ListOfnum().is(a));
        expect$.Expect.equals(false, ListOfString().is(a));
      }
      {
        let a = ListOfnum().new(5);
        expect$.Expect.equals(true, core.List.is(a));
        expect$.Expect.equals(true, ListOfObject().is(a));
        expect$.Expect.equals(false, ListOfint().is(a));
        expect$.Expect.equals(true, ListOfnum().is(a));
        expect$.Expect.equals(false, ListOfString().is(a));
      }
      {
        let a = ListOfString().new(5);
        expect$.Expect.equals(true, core.List.is(a));
        expect$.Expect.equals(true, ListOfObject().is(a));
        expect$.Expect.equals(false, ListOfint().is(a));
        expect$.Expect.equals(false, ListOfnum().is(a));
        expect$.Expect.equals(true, ListOfString().is(a));
      }
    }
  };
  dart.setSignature(instanceof2_test.InstanceofTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  instanceof2_test.main = function() {
    for (let i = 0; i < 5; i++) {
      instanceof2_test.InstanceofTest.testMain();
    }
  };
  dart.fn(instanceof2_test.main, VoidTodynamic());
  // Exports:
  exports.instanceof2_test = instanceof2_test;
});
