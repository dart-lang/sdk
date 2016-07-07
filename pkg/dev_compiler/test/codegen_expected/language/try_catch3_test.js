dart_library.library('language/try_catch3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__try_catch3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const try_catch3_test = Object.create(null);
  let MyParameterizedException = () => (MyParameterizedException = dart.constFn(try_catch3_test.MyParameterizedException$()))();
  let MyParameterizedExceptionOfString$TestException = () => (MyParameterizedExceptionOfString$TestException = dart.constFn(try_catch3_test.MyParameterizedException$(core.String, try_catch3_test.TestException)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  try_catch3_test.TestException = class TestException extends core.Object {};
  const _message = Symbol('_message');
  try_catch3_test.MyException = class MyException extends core.Object {
    new(message) {
      if (message === void 0) message = "";
      this[_message] = message;
    }
    getMessage() {
      return this[_message];
    }
  };
  try_catch3_test.MyException[dart.implements] = () => [try_catch3_test.TestException];
  dart.setSignature(try_catch3_test.MyException, {
    constructors: () => ({new: dart.definiteFunctionType(try_catch3_test.MyException, [], [core.String])}),
    methods: () => ({getMessage: dart.definiteFunctionType(core.String, [])})
  });
  try_catch3_test.MyParameterizedException$ = dart.generic((U, V) => {
    class MyParameterizedException extends core.Object {
      new(message) {
        if (message === void 0) message = "";
        this[_message] = message;
      }
      getMessage() {
        return this[_message];
      }
    }
    dart.addTypeTests(MyParameterizedException);
    MyParameterizedException[dart.implements] = () => [try_catch3_test.TestException];
    dart.setSignature(MyParameterizedException, {
      constructors: () => ({new: dart.definiteFunctionType(try_catch3_test.MyParameterizedException$(U, V), [], [core.String])}),
      methods: () => ({getMessage: dart.definiteFunctionType(core.String, [])})
    });
    return MyParameterizedException;
  });
  try_catch3_test.MyParameterizedException = MyParameterizedException();
  try_catch3_test.StackTrace = class StackTrace extends core.Object {
    new() {
    }
    printStackTrace(ex) {
      core.print(ex);
    }
  };
  dart.setSignature(try_catch3_test.StackTrace, {
    constructors: () => ({new: dart.definiteFunctionType(try_catch3_test.StackTrace, [])}),
    methods: () => ({printStackTrace: dart.definiteFunctionType(dart.dynamic, [try_catch3_test.TestException])})
  });
  try_catch3_test.Helper = class Helper extends core.Object {
    static test1(i) {
      try {
        let j = null;
        j = try_catch3_test.Helper.f2();
        j = try_catch3_test.Helper.f3();
        try {
          let k = try_catch3_test.Helper.f2();
          try_catch3_test.Helper.f3();
        } catch (e$) {
          if (try_catch3_test.MyException.is(e$)) {
            let ex = e$;
            let i = 10;
            core.print(i);
          } else if (try_catch3_test.TestException.is(e$)) {
            let ex = e$;
            let k = 10;
            core.print(k);
          } else
            throw e$;
        }

        try {
          j = dart.notNull(j) + 24;
        } catch (e) {
          i = 300;
          core.print(dart.dsend(e, 'getMessage'));
        }

        try {
          j = dart.notNull(j) + 20;
        } catch (e) {
          i = 400;
          core.print(dart.dsend(e, 'getMessage'));
        }

        try {
          j = dart.notNull(j) + 40;
        } catch (e) {
          i = 600;
          core.print(dart.dsend(e, 'getMessage'));
        }

        try {
          j = dart.notNull(j) + 60;
        } catch (e) {
          let trace = dart.stackTrace(e);
          i = 700;
          core.print(trace.toString());
          core.print(dart.dsend(e, 'getMessage'));
        }

        try {
          j = dart.notNull(j) + 80;
        } catch (e) {
          if (try_catch3_test.MyException.is(e)) {
            i = 500;
            core.print(e.getMessage());
          } else
            throw e;
        }

      } catch (e$0) {
        if (MyParameterizedExceptionOfString$TestException().is(e$0)) {
          let e = e$0;
          let trace = dart.stackTrace(e);
          i = 800;
          core.print(trace.toString());
          throw e;
        } else if (try_catch3_test.MyException.is(e$0)) {
          let exception = e$0;
          i = 100;
          core.print(exception.getMessage());
        } else if (try_catch3_test.TestException.is(e$0)) {
          let e = e$0;
          let trace = dart.stackTrace(e);
          i = 200;
          core.print(trace.toString());
        } else
          throw e$0;
      }
 finally {
        i = 900;
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
  dart.setSignature(try_catch3_test.Helper, {
    statics: () => ({
      test1: dart.definiteFunctionType(core.int, [core.int]),
      f2: dart.definiteFunctionType(core.int, []),
      f3: dart.definiteFunctionType(core.int, [])
    }),
    names: ['test1', 'f2', 'f3']
  });
  try_catch3_test.TryCatchTest = class TryCatchTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(900, try_catch3_test.Helper.test1(1));
    }
  };
  dart.setSignature(try_catch3_test.TryCatchTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  try_catch3_test.main = function() {
    for (let i = 0; i < 20; i++) {
      try_catch3_test.TryCatchTest.testMain();
    }
  };
  dart.fn(try_catch3_test.main, VoidTodynamic());
  // Exports:
  exports.try_catch3_test = try_catch3_test;
});
