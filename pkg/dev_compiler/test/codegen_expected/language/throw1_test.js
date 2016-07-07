dart_library.library('language/throw1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__throw1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const throw1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  throw1_test.TestException = class TestException extends core.Object {};
  throw1_test.MyException = class MyException extends core.Object {
    new(message) {
      if (message === void 0) message = "";
      this.message_ = message;
    }
    getMessage() {
      return this.message_;
    }
  };
  throw1_test.MyException[dart.implements] = () => [throw1_test.TestException];
  dart.setSignature(throw1_test.MyException, {
    constructors: () => ({new: dart.definiteFunctionType(throw1_test.MyException, [], [core.String])}),
    methods: () => ({getMessage: dart.definiteFunctionType(core.String, [])})
  });
  throw1_test.MyException2 = class MyException2 extends core.Object {
    new(message) {
      if (message === void 0) message = "";
      this.message_ = message;
    }
    getMessage() {
      return this.message_;
    }
  };
  throw1_test.MyException2[dart.implements] = () => [throw1_test.TestException];
  dart.setSignature(throw1_test.MyException2, {
    constructors: () => ({new: dart.definiteFunctionType(throw1_test.MyException2, [], [core.String])}),
    methods: () => ({getMessage: dart.definiteFunctionType(core.String, [])})
  });
  throw1_test.MyException3 = class MyException3 extends core.Object {
    new(message) {
      if (message === void 0) message = "";
      this.message_ = message;
    }
    getMessage() {
      return this.message_;
    }
  };
  throw1_test.MyException3[dart.implements] = () => [throw1_test.TestException];
  dart.setSignature(throw1_test.MyException3, {
    constructors: () => ({new: dart.definiteFunctionType(throw1_test.MyException3, [], [core.String])}),
    methods: () => ({getMessage: dart.definiteFunctionType(core.String, [])})
  });
  throw1_test.Helper = class Helper extends core.Object {
    static f1(i) {
      try {
        let j = null;
        j = throw1_test.Helper.func();
        if (dart.notNull(j) > 0) {
          dart.throw(new throw1_test.MyException2("Test for exception being thrown"));
        }
      } catch (e) {
        if (throw1_test.MyException3.is(e)) {
          let exception = e;
          i = 100;
          core.print(exception.getMessage());
        } else if (throw1_test.TestException.is(e)) {
          let exception = e;
          i = 50;
          core.print(exception.getMessage());
        } else if (throw1_test.MyException2.is(e)) {
          let exception = e;
          i = 150;
          core.print(exception.getMessage());
        } else if (throw1_test.MyException.is(e)) {
          let exception = e;
          i = 200;
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
      return i;
    }
  };
  dart.setSignature(throw1_test.Helper, {
    statics: () => ({
      f1: dart.definiteFunctionType(core.int, [core.int]),
      func: dart.definiteFunctionType(core.int, [])
    }),
    names: ['f1', 'func']
  });
  throw1_test.Throw1Test = class Throw1Test extends core.Object {
    static testMain() {
      expect$.Expect.equals(850, throw1_test.Helper.f1(1));
    }
  };
  dart.setSignature(throw1_test.Throw1Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  throw1_test.main = function() {
    throw1_test.Throw1Test.testMain();
  };
  dart.fn(throw1_test.main, VoidTodynamic());
  // Exports:
  exports.throw1_test = throw1_test;
});
