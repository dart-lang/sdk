dart_library.library('language/try_catch2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__try_catch2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const try_catch2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  try_catch2_test.TestException = class TestException extends core.Object {};
  try_catch2_test.MyException = class MyException extends core.Object {
    new(message) {
      if (message === void 0) message = "";
      this.message_ = message;
    }
    getMessage() {
      return this.message_;
    }
  };
  try_catch2_test.MyException[dart.implements] = () => [try_catch2_test.TestException];
  dart.setSignature(try_catch2_test.MyException, {
    constructors: () => ({new: dart.definiteFunctionType(try_catch2_test.MyException, [], [core.String])}),
    methods: () => ({getMessage: dart.definiteFunctionType(core.String, [])})
  });
  try_catch2_test.StackTrace = class StackTrace extends core.Object {
    new() {
    }
  };
  dart.setSignature(try_catch2_test.StackTrace, {
    constructors: () => ({new: dart.definiteFunctionType(try_catch2_test.StackTrace, [])})
  });
  try_catch2_test.Helper = class Helper extends core.Object {
    static f1(i) {
      try {
        let j = null;
        j = try_catch2_test.Helper.f2();
        i = dart.notNull(i) + 1;
        try {
          j = dart.notNull(try_catch2_test.Helper.f2()) + dart.notNull(try_catch2_test.Helper.f3()) + dart.notNull(j);
          i = dart.notNull(i) + 1;
        } catch (e) {
          if (try_catch2_test.TestException.is(e)) {
            let trace = dart.stackTrace(e);
            j = 50;
          } else
            throw e;
        }

        j = dart.notNull(try_catch2_test.Helper.f3()) + dart.notNull(j);
      } catch (e$) {
        if (try_catch2_test.MyException.is(e$)) {
          let exception = e$;
          i = 100;
        } else if (try_catch2_test.TestException.is(e$)) {
          let e = e$;
          let trace = dart.stackTrace(e);
          i = 200;
        } else
          throw e$;
      }

      return i;
    }
    static f2() {
      return 2;
    }
    static f3() {
      let i = 0;
      while (i < 10) {
        i++;
      }
      return i;
    }
  };
  dart.setSignature(try_catch2_test.Helper, {
    statics: () => ({
      f1: dart.definiteFunctionType(core.int, [core.int]),
      f2: dart.definiteFunctionType(core.int, []),
      f3: dart.definiteFunctionType(core.int, [])
    }),
    names: ['f1', 'f2', 'f3']
  });
  try_catch2_test.TryCatch2Test = class TryCatch2Test extends core.Object {
    static testMain() {
      expect$.Expect.equals(3, try_catch2_test.Helper.f1(1));
    }
  };
  dart.setSignature(try_catch2_test.TryCatch2Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  try_catch2_test.main = function() {
    for (let i = 0; i < 20; i++) {
      try_catch2_test.TryCatch2Test.testMain();
    }
  };
  dart.fn(try_catch2_test.main, VoidTodynamic());
  // Exports:
  exports.try_catch2_test = try_catch2_test;
});
