dart_library.library('language/instanceof_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__instanceof_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const instanceof_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  instanceof_test.InstanceofTest = class InstanceofTest extends core.Object {
    new() {
    }
    static testBasicTypes() {
      expect$.Expect.equals(true, typeof 0 == 'number');
      expect$.Expect.equals(false, typeof 0 == 'boolean');
      expect$.Expect.equals(false, typeof 0 == 'string');
      expect$.Expect.equals(true, typeof 1 == 'number');
      expect$.Expect.equals(false, typeof 1 == 'boolean');
      expect$.Expect.equals(false, typeof 1 == 'string');
      expect$.Expect.equals(false, typeof true == 'number');
      expect$.Expect.equals(true, typeof true == 'boolean');
      expect$.Expect.equals(false, typeof true == 'string');
      expect$.Expect.equals(false, typeof false == 'number');
      expect$.Expect.equals(true, typeof false == 'boolean');
      expect$.Expect.equals(false, typeof false == 'string');
      expect$.Expect.equals(false, typeof "a" == 'number');
      expect$.Expect.equals(false, typeof "a" == 'boolean');
      expect$.Expect.equals(true, typeof "a" == 'string');
      expect$.Expect.equals(false, typeof "" == 'number');
      expect$.Expect.equals(false, typeof "" == 'boolean');
      expect$.Expect.equals(true, typeof "" == 'string');
    }
    static testInterfaces() {
      let a = new instanceof_test.A();
      expect$.Expect.equals(true, instanceof_test.I.is(a));
      expect$.Expect.equals(true, instanceof_test.A.is(a));
      expect$.Expect.equals(false, typeof a == 'string');
      expect$.Expect.equals(false, typeof a == 'number');
      expect$.Expect.equals(false, typeof a == 'boolean');
      expect$.Expect.equals(false, instanceof_test.B.is(a));
      expect$.Expect.equals(false, instanceof_test.J.is(a));
      let c = new instanceof_test.C();
      expect$.Expect.equals(true, instanceof_test.I.is(c));
      expect$.Expect.equals(true, instanceof_test.J.is(c));
      expect$.Expect.equals(true, instanceof_test.K.is(c));
      let d = new instanceof_test.D();
      expect$.Expect.equals(true, instanceof_test.I.is(d));
      expect$.Expect.equals(true, instanceof_test.J.is(d));
      expect$.Expect.equals(true, instanceof_test.K.is(d));
      expect$.Expect.equals(true, core.List.is([]));
      expect$.Expect.equals(true, core.List.is(JSArrayOfint().of([1, 2, 3])));
      expect$.Expect.equals(false, core.List.is(d));
      expect$.Expect.equals(false, core.List.is(null));
      expect$.Expect.equals(false, instanceof_test.D.is(null));
    }
    static testnum() {
      expect$.Expect.equals(true, typeof 0 == 'number');
      expect$.Expect.equals(true, typeof 123 == 'number');
      expect$.Expect.equals(true, typeof 123.34 == 'number');
      expect$.Expect.equals(false, typeof "123" == 'number');
      expect$.Expect.equals(false, typeof null == 'number');
      expect$.Expect.equals(false, typeof true == 'number');
      expect$.Expect.equals(false, typeof false == 'number');
      let a = new instanceof_test.A();
      expect$.Expect.equals(false, typeof a == 'number');
    }
    static testTypeOfInstanceOf() {
      let a = new instanceof_test.A();
      let c = new instanceof_test.C();
      let d = new instanceof_test.D();
      expect$.Expect.equals(true, typeof (typeof null == 'number') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof null == 'boolean') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof null == 'string') == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.A.is(null) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.B.is(null) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.I.is(null) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.J.is(null) == 'boolean');
      expect$.Expect.equals(true, typeof (typeof 0 == 'number') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof 0 == 'boolean') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof 0 == 'string') == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.A.is(0) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.B.is(0) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.I.is(0) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.J.is(0) == 'boolean');
      expect$.Expect.equals(true, typeof (typeof 1 == 'number') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof 1 == 'boolean') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof 1 == 'string') == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.A.is(1) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.B.is(1) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.I.is(1) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.J.is(1) == 'boolean');
      expect$.Expect.equals(true, typeof (typeof true == 'number') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof true == 'boolean') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof true == 'string') == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.A.is(true) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.B.is(true) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.I.is(true) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.J.is(true) == 'boolean');
      expect$.Expect.equals(true, typeof (typeof false == 'number') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof false == 'boolean') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof false == 'string') == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.A.is(false) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.B.is(false) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.I.is(false) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.J.is(false) == 'boolean');
      expect$.Expect.equals(true, typeof (typeof "a" == 'number') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof "a" == 'boolean') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof "a" == 'string') == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.A.is("a") == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.B.is("a") == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.I.is("a") == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.J.is("a") == 'boolean');
      expect$.Expect.equals(true, typeof (typeof "" == 'number') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof "" == 'boolean') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof "" == 'string') == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.A.is("") == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.B.is("") == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.I.is("") == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.J.is("") == 'boolean');
      expect$.Expect.equals(true, typeof (typeof a == 'number') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof a == 'boolean') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof a == 'string') == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.A.is(a) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.B.is(a) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.I.is(a) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.J.is(a) == 'boolean');
      expect$.Expect.equals(true, typeof (typeof c == 'number') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof c == 'boolean') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof c == 'string') == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.A.is(c) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.B.is(c) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.I.is(c) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.J.is(c) == 'boolean');
      expect$.Expect.equals(true, typeof (typeof d == 'number') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof d == 'boolean') == 'boolean');
      expect$.Expect.equals(true, typeof (typeof d == 'string') == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.A.is(d) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.B.is(d) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.I.is(d) == 'boolean');
      expect$.Expect.equals(true, typeof instanceof_test.J.is(d) == 'boolean');
    }
    static testMain() {
      instanceof_test.InstanceofTest.testBasicTypes();
      instanceof_test.InstanceofTest.testInterfaces();
      instanceof_test.InstanceofTest.testTypeOfInstanceOf();
    }
  };
  dart.setSignature(instanceof_test.InstanceofTest, {
    constructors: () => ({new: dart.definiteFunctionType(instanceof_test.InstanceofTest, [])}),
    statics: () => ({
      testBasicTypes: dart.definiteFunctionType(dart.void, []),
      testInterfaces: dart.definiteFunctionType(dart.void, []),
      testnum: dart.definiteFunctionType(dart.void, []),
      testTypeOfInstanceOf: dart.definiteFunctionType(dart.void, []),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testBasicTypes', 'testInterfaces', 'testnum', 'testTypeOfInstanceOf', 'testMain']
  });
  instanceof_test.I = class I extends core.Object {};
  instanceof_test.A = class A extends core.Object {
    new() {
    }
  };
  instanceof_test.A[dart.implements] = () => [instanceof_test.I];
  dart.setSignature(instanceof_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(instanceof_test.A, [])})
  });
  instanceof_test.B = class B extends core.Object {
    new() {
    }
  };
  dart.setSignature(instanceof_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(instanceof_test.B, [])})
  });
  instanceof_test.J = class J extends core.Object {};
  instanceof_test.K = class K extends core.Object {};
  instanceof_test.K[dart.implements] = () => [instanceof_test.J];
  instanceof_test.C = class C extends core.Object {
    new() {
    }
  };
  instanceof_test.C[dart.implements] = () => [instanceof_test.I, instanceof_test.K];
  dart.setSignature(instanceof_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(instanceof_test.C, [])})
  });
  instanceof_test.D = class D extends instanceof_test.C {
    new() {
      super.new();
    }
  };
  dart.setSignature(instanceof_test.D, {
    constructors: () => ({new: dart.definiteFunctionType(instanceof_test.D, [])})
  });
  instanceof_test.main = function() {
    for (let i = 0; i < 5; i++) {
      instanceof_test.InstanceofTest.testMain();
    }
  };
  dart.fn(instanceof_test.main, VoidTodynamic());
  // Exports:
  exports.instanceof_test = instanceof_test;
});
