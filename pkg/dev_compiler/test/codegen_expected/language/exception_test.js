dart_library.library('language/exception_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__exception_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const exception_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  exception_test.ExceptionTest = class ExceptionTest extends core.Object {
    static testMain() {
      let i = 0;
      try {
        dart.throw("Hello");
      } catch (s) {
        if (core.String.is(s)) {
          core.print(s);
          i = i + 10;
        } else
          throw s;
      }

      try {
        dart.throw("bye");
      } catch (s) {
        if (core.String.is(s)) {
          core.print(s);
          i = i + 10;
        } else
          throw s;
      }

      expect$.Expect.equals(20, i);
      let correctCatch = false;
      try {
        dart.throw(null);
      } catch (e$) {
        if (core.String.is(e$)) {
          let s = e$;
          correctCatch = false;
        } else if (core.NullThrownError.is(e$)) {
          let e = e$;
          correctCatch = true;
        } else {
          let x = e$;
          correctCatch = false;
        }
      }

      expect$.Expect.isTrue(correctCatch);
    }
  };
  dart.setSignature(exception_test.ExceptionTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  exception_test.main = function() {
    exception_test.ExceptionTest.testMain();
  };
  dart.fn(exception_test.main, VoidTodynamic());
  // Exports:
  exports.exception_test = exception_test;
});
