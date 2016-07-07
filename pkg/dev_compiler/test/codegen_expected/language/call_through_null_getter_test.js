dart_library.library('language/call_through_null_getter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__call_through_null_getter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const call_through_null_getter_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  call_through_null_getter_test.TOP_LEVEL_NULL = null;
  call_through_null_getter_test.topLevel = null;
  call_through_null_getter_test.CallThroughNullGetterTest = class CallThroughNullGetterTest extends core.Object {
    static testMain() {
      call_through_null_getter_test.CallThroughNullGetterTest.testTopLevel();
      call_through_null_getter_test.CallThroughNullGetterTest.testField();
      call_through_null_getter_test.CallThroughNullGetterTest.testGetter();
      call_through_null_getter_test.CallThroughNullGetterTest.testMethod();
    }
    static testTopLevel() {
      call_through_null_getter_test.topLevel = null;
      call_through_null_getter_test.CallThroughNullGetterTest.expectThrowsNoSuchMethodError(dart.fn(() => {
        dart.dcall(call_through_null_getter_test.topLevel);
      }, VoidTodynamic()));
      call_through_null_getter_test.CallThroughNullGetterTest.expectThrowsNoSuchMethodError(dart.fn(() => {
        dart.dcall(call_through_null_getter_test.topLevel);
      }, VoidTodynamic()));
      call_through_null_getter_test.CallThroughNullGetterTest.expectThrowsNoSuchMethodError(dart.fn(() => {
        dart.dcall(call_through_null_getter_test.TOP_LEVEL_NULL);
      }, VoidTodynamic()));
      call_through_null_getter_test.CallThroughNullGetterTest.expectThrowsNoSuchMethodError(dart.fn(() => {
        dart.dcall(call_through_null_getter_test.TOP_LEVEL_NULL);
      }, VoidTodynamic()));
    }
    static testField() {
      let a = new call_through_null_getter_test.A();
      a.field = null;
      call_through_null_getter_test.CallThroughNullGetterTest.expectThrowsNoSuchMethodError(dart.fn(() => {
        dart.dsend(a, 'field');
      }, VoidTodynamic()));
      call_through_null_getter_test.CallThroughNullGetterTest.expectThrowsNoSuchMethodError(dart.fn(() => {
        dart.dcall(a.field);
      }, VoidTodynamic()));
    }
    static testGetter() {
      let a = new call_through_null_getter_test.A();
      a.field = null;
      call_through_null_getter_test.CallThroughNullGetterTest.expectThrowsNoSuchMethodError(dart.fn(() => {
        dart.dsend(a, 'getter');
      }, VoidTodynamic()));
      call_through_null_getter_test.CallThroughNullGetterTest.expectThrowsNoSuchMethodError(dart.fn(() => {
        dart.dcall(a.getter);
      }, VoidTodynamic()));
    }
    static testMethod() {
      let a = new call_through_null_getter_test.A();
      a.field = null;
      call_through_null_getter_test.CallThroughNullGetterTest.expectThrowsNoSuchMethodError(dart.fn(() => {
        dart.dcall(a.method());
      }, VoidTodynamic()));
    }
    static expectThrowsNoSuchMethodError(fn) {
      expect$.Expect.throws(VoidTovoid()._check(fn), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()), "Should throw NoSuchMethodError");
    }
  };
  dart.setSignature(call_through_null_getter_test.CallThroughNullGetterTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.void, []),
      testTopLevel: dart.definiteFunctionType(dart.void, []),
      testField: dart.definiteFunctionType(dart.void, []),
      testGetter: dart.definiteFunctionType(dart.void, []),
      testMethod: dart.definiteFunctionType(dart.void, []),
      expectThrowsNoSuchMethodError: dart.definiteFunctionType(dart.void, [dart.dynamic])
    }),
    names: ['testMain', 'testTopLevel', 'testField', 'testGetter', 'testMethod', 'expectThrowsNoSuchMethodError']
  });
  call_through_null_getter_test.A = class A extends core.Object {
    new() {
      this.field = null;
    }
    get getter() {
      return this.field;
    }
    method() {
      return this.field;
    }
  };
  dart.setSignature(call_through_null_getter_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(call_through_null_getter_test.A, [])}),
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [])})
  });
  call_through_null_getter_test.main = function() {
    call_through_null_getter_test.CallThroughNullGetterTest.testMain();
  };
  dart.fn(call_through_null_getter_test.main, VoidTodynamic());
  // Exports:
  exports.call_through_null_getter_test = call_through_null_getter_test;
});
