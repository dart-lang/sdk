dart_library.library('language/method_invocation_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__method_invocation_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const method_invocation_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  method_invocation_test.A = class A extends core.Object {
    new() {
    }
    foo() {
      return 1;
    }
  };
  dart.setSignature(method_invocation_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(method_invocation_test.A, [])}),
    methods: () => ({foo: dart.definiteFunctionType(core.int, [])})
  });
  method_invocation_test.B = class B extends core.Object {
    get f() {
      dart.throw(123);
    }
  };
  method_invocation_test.MethodInvocationTest = class MethodInvocationTest extends core.Object {
    static testNullReceiver() {
      let a = new method_invocation_test.A();
      expect$.Expect.equals(1, a.foo());
      a = null;
      let exceptionCaught = false;
      try {
        a.foo();
      } catch (e) {
        if (core.NoSuchMethodError.is(e)) {
          exceptionCaught = true;
        } else
          throw e;
      }

      expect$.Expect.equals(true, exceptionCaught);
    }
    static testGetterMethodInvocation() {
      let b = new method_invocation_test.B();
      try {
        dart.dsend(b, 'f');
      } catch (e) {
        expect$.Expect.equals(123, e);
      }

    }
    static testMain() {
      method_invocation_test.MethodInvocationTest.testNullReceiver();
      method_invocation_test.MethodInvocationTest.testGetterMethodInvocation();
    }
  };
  dart.setSignature(method_invocation_test.MethodInvocationTest, {
    statics: () => ({
      testNullReceiver: dart.definiteFunctionType(dart.void, []),
      testGetterMethodInvocation: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testNullReceiver', 'testGetterMethodInvocation', 'testMain']
  });
  method_invocation_test.main = function() {
    method_invocation_test.MethodInvocationTest.testMain();
  };
  dart.fn(method_invocation_test.main, VoidTodynamic());
  // Exports:
  exports.method_invocation_test = method_invocation_test;
});
