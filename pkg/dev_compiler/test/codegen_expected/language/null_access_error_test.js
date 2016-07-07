dart_library.library('language/null_access_error_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null_access_error_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null_access_error_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  null_access_error_test.NullAccessTest = class NullAccessTest extends core.Object {
    static testNullVariable() {
      let variable = null;
      let exceptionCaught = false;
      let wrongExceptionCaught = false;
      try {
        variable = dart.notNull(variable) + 1;
      } catch (e) {
        if (core.NoSuchMethodError.is(e)) {
          let ex = e;
          exceptionCaught = true;
        } else {
          let ex = e;
          wrongExceptionCaught = true;
        }
      }

      expect$.Expect.isTrue(exceptionCaught);
      expect$.Expect.isFalse(wrongExceptionCaught);
    }
    static helperFunction(parameter) {
      let x = parameter;
      parameter = dart.notNull(x) + 1;
      return x;
    }
    static testNullFunctionCall() {
      let variable = null;
      let exceptionCaught = false;
      let wrongExceptionCaught = false;
      try {
        variable = null_access_error_test.NullAccessTest.helperFunction(variable);
      } catch (e) {
        if (core.NoSuchMethodError.is(e)) {
          let ex = e;
          exceptionCaught = true;
        } else {
          let ex = e;
          wrongExceptionCaught = true;
        }
      }

      expect$.Expect.isTrue(exceptionCaught);
      expect$.Expect.isFalse(wrongExceptionCaught);
    }
    static testMain() {
      null_access_error_test.NullAccessTest.testNullVariable();
      null_access_error_test.NullAccessTest.testNullFunctionCall();
    }
  };
  dart.setSignature(null_access_error_test.NullAccessTest, {
    statics: () => ({
      testNullVariable: dart.definiteFunctionType(dart.void, []),
      helperFunction: dart.definiteFunctionType(core.int, [core.int]),
      testNullFunctionCall: dart.definiteFunctionType(dart.void, []),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testNullVariable', 'helperFunction', 'testNullFunctionCall', 'testMain']
  });
  null_access_error_test.main = function() {
    null_access_error_test.NullAccessTest.testMain();
  };
  dart.fn(null_access_error_test.main, VoidTodynamic());
  // Exports:
  exports.null_access_error_test = null_access_error_test;
});
