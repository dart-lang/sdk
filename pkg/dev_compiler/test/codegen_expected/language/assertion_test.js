dart_library.library('language/assertion_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__assertion_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const assertion_test = Object.create(null);
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  assertion_test.AssertionTest = class AssertionTest extends core.Object {
    static testTrue() {
      let i = 0;
      try {
        dart.assert(true);
      } catch (error) {
        if (core.AssertionError.is(error)) {
          i = 1;
        } else
          throw error;
      }

      return i;
    }
    static testFalse() {
      let i = 0;
      try {
        dart.assert(false);
      } catch (error) {
        if (core.AssertionError.is(error)) {
          i = 1;
        } else
          throw error;
      }

      return i;
    }
    static unknown(a) {
      return dart.test(a) ? true : false;
    }
    static testUnknown() {
      let x = assertion_test.AssertionTest.unknown(false);
      let i = 0;
      try {
        dart.assert(x);
      } catch (error) {
        if (core.AssertionError.is(error)) {
          i = 1;
        } else
          throw error;
      }

      return i;
    }
    static testClosure() {
      let i = 0;
      try {
        dart.assert(dart.fn(() => false, VoidTobool()));
      } catch (error) {
        if (core.AssertionError.is(error)) {
          i = 1;
        } else
          throw error;
      }

      return i;
    }
    static testClosure2() {
      let i = 0;
      try {
        let x = dart.fn(() => false, VoidTobool());
        dart.assert(x);
      } catch (error) {
        if (core.AssertionError.is(error)) {
          i = 1;
        } else
          throw error;
      }

      return i;
    }
    static testMain() {
      expect$.Expect.equals(0, assertion_test.AssertionTest.testTrue());
      expect$.Expect.equals(1, assertion_test.AssertionTest.testFalse());
      expect$.Expect.equals(1, assertion_test.AssertionTest.testClosure());
      expect$.Expect.equals(1, assertion_test.AssertionTest.testClosure2());
    }
  };
  dart.setSignature(assertion_test.AssertionTest, {
    statics: () => ({
      testTrue: dart.definiteFunctionType(dart.dynamic, []),
      testFalse: dart.definiteFunctionType(dart.dynamic, []),
      unknown: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testUnknown: dart.definiteFunctionType(dart.dynamic, []),
      testClosure: dart.definiteFunctionType(dart.dynamic, []),
      testClosure2: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['testTrue', 'testFalse', 'unknown', 'testUnknown', 'testClosure', 'testClosure2', 'testMain']
  });
  assertion_test.main = function() {
    assertion_test.AssertionTest.testMain();
  };
  dart.fn(assertion_test.main, VoidTodynamic());
  // Exports:
  exports.assertion_test = assertion_test;
});
