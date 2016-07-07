dart_library.library('language/throw2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__throw2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const throw2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  throw2_test.TestException = class TestException extends core.Object {};
  throw2_test.MyException = class MyException extends core.Object {
    new(message) {
      if (message === void 0) message = "";
      this.message_ = message;
    }
    getMessage() {
      return this.message_;
    }
  };
  throw2_test.MyException[dart.implements] = () => [throw2_test.TestException];
  dart.setSignature(throw2_test.MyException, {
    constructors: () => ({new: dart.definiteFunctionType(throw2_test.MyException, [], [core.String])}),
    methods: () => ({getMessage: dart.definiteFunctionType(core.String, [])})
  });
  throw2_test.MyException2 = class MyException2 extends core.Object {
    new(message) {
      if (message === void 0) message = "";
      this.message_ = message;
    }
    getMessage() {
      return this.message_;
    }
  };
  throw2_test.MyException2[dart.implements] = () => [throw2_test.TestException];
  dart.setSignature(throw2_test.MyException2, {
    constructors: () => ({new: dart.definiteFunctionType(throw2_test.MyException2, [], [core.String])}),
    methods: () => ({getMessage: dart.definiteFunctionType(core.String, [])})
  });
  throw2_test.MyException3 = class MyException3 extends core.Object {
    new(message) {
      if (message === void 0) message = "";
      this.message_ = message;
    }
    getMessage() {
      return this.message_;
    }
  };
  throw2_test.MyException3[dart.implements] = () => [throw2_test.TestException];
  dart.setSignature(throw2_test.MyException3, {
    constructors: () => ({new: dart.definiteFunctionType(throw2_test.MyException3, [], [core.String])}),
    methods: () => ({getMessage: dart.definiteFunctionType(core.String, [])})
  });
  throw2_test.Helper = class Helper extends core.Object {
    static f1(i) {
      try {
        let j = null;
        j = throw2_test.Helper.func();
      } catch (e) {
        if (throw2_test.MyException3.is(e)) {
          let exception = e;
          i = 100;
          core.print(exception.getMessage());
        } else if (throw2_test.MyException2.is(e)) {
          let exception = e;
          try {
            i = throw2_test.Helper.func2();
            i = 200;
          } catch (exception) {
            if (throw2_test.TestException.is(exception)) {
              i = 50;
            } else
              throw exception;
          }

          core.print(exception.getMessage());
        } else if (throw2_test.MyException.is(e)) {
          let exception = e;
          i = throw2_test.Helper.func2();
          core.print(exception.getMessage());
        } else
          throw e;
      }
 finally {
        i = dart.notNull(i) + 800;
      }
      return i;
    }
    static func() {
      let i = 0;
      while (i < 10) {
        i++;
      }
      if (i > 0) {
        dart.throw(new throw2_test.MyException2("Test for exception being thrown"));
      }
      return i;
    }
    static func2() {
      let i = 0;
      while (i < 10) {
        i++;
      }
      if (i > 0) {
        dart.throw(new throw2_test.MyException2("Test for exception being thrown"));
      }
      return i;
    }
  };
  dart.setSignature(throw2_test.Helper, {
    statics: () => ({
      f1: dart.definiteFunctionType(core.int, [core.int]),
      func: dart.definiteFunctionType(core.int, []),
      func2: dart.definiteFunctionType(core.int, [])
    }),
    names: ['f1', 'func', 'func2']
  });
  throw2_test.Throw2Test = class Throw2Test extends core.Object {
    static testMain() {
      expect$.Expect.equals(850, throw2_test.Helper.f1(1));
    }
  };
  dart.setSignature(throw2_test.Throw2Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  throw2_test.main = function() {
    throw2_test.Throw2Test.testMain();
  };
  dart.fn(throw2_test.main, VoidTodynamic());
  // Exports:
  exports.throw2_test = throw2_test;
});
