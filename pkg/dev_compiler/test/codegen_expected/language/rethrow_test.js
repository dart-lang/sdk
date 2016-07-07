dart_library.library('language/rethrow_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rethrow_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rethrow_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  rethrow_test.MyException = class MyException extends core.Object {
    new() {
    }
  };
  dart.setSignature(rethrow_test.MyException, {
    constructors: () => ({new: dart.definiteFunctionType(rethrow_test.MyException, [])})
  });
  rethrow_test.OtherException = class OtherException extends core.Object {
    new() {
    }
  };
  dart.setSignature(rethrow_test.OtherException, {
    constructors: () => ({new: dart.definiteFunctionType(rethrow_test.OtherException, [])})
  });
  rethrow_test.RethrowTest = class RethrowTest extends core.Object {
    new() {
      this.currentException = null;
    }
    throwException() {
      this.currentException = new rethrow_test.MyException();
      dart.throw(this.currentException);
    }
    testRethrowPastUncaught() {
      try {
        try {
          try {
            this.throwException();
            expect$.Expect.fail("Should have thrown an exception");
          } catch (e) {
            expect$.Expect.equals(true, core.identical(e, this.currentException));
            throw e;
            expect$.Expect.fail("Should have thrown an exception");
          }

        } catch (e) {
          if (rethrow_test.OtherException.is(e)) {
            expect$.Expect.fail("Should not have caught OtherException");
          } else
            throw e;
        }

      } catch (e) {
        expect$.Expect.equals(true, core.identical(e, this.currentException));
      }

    }
    testRethrow() {
      try {
        try {
          this.throwException();
          expect$.Expect.fail("Should have thrown an exception");
        } catch (e) {
          expect$.Expect.equals(true, core.identical(e, this.currentException));
          throw e;
          expect$.Expect.fail("Should have thrown an exception");
        }

      } catch (e) {
        expect$.Expect.equals(true, core.identical(e, this.currentException));
      }

    }
  };
  dart.setSignature(rethrow_test.RethrowTest, {
    methods: () => ({
      throwException: dart.definiteFunctionType(dart.void, []),
      testRethrowPastUncaught: dart.definiteFunctionType(dart.void, []),
      testRethrow: dart.definiteFunctionType(dart.void, [])
    })
  });
  rethrow_test.main = function() {
    let t = new rethrow_test.RethrowTest();
    t.testRethrow();
    t.testRethrowPastUncaught();
  };
  dart.fn(rethrow_test.main, VoidTodynamic());
  // Exports:
  exports.rethrow_test = rethrow_test;
});
