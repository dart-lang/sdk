dart_library.library('language/throw5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__throw5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const throw5_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  throw5_test.MyException1 = class MyException1 extends core.Object {
    new(message) {
      if (message === void 0) message = "1";
      this.message_ = message;
    }
  };
  dart.setSignature(throw5_test.MyException1, {
    constructors: () => ({new: dart.definiteFunctionType(throw5_test.MyException1, [], [core.String])})
  });
  throw5_test.MyException2 = class MyException2 extends core.Object {
    new(message) {
      if (message === void 0) message = "2";
      this.message_ = message;
    }
  };
  dart.setSignature(throw5_test.MyException2, {
    constructors: () => ({new: dart.definiteFunctionType(throw5_test.MyException2, [], [core.String])})
  });
  throw5_test.MyException3 = class MyException3 extends core.Object {
    new(message) {
      if (message === void 0) message = "3";
      this.message_ = message;
    }
  };
  dart.setSignature(throw5_test.MyException3, {
    constructors: () => ({new: dart.definiteFunctionType(throw5_test.MyException3, [], [core.String])})
  });
  throw5_test.Helper = class Helper extends core.Object {
    static f1(i) {
      try {
        let j = null;
        j = throw5_test.Helper.func();
      } catch (e) {
        if (throw5_test.MyException3.is(e)) {
          let exception = e;
          i = 300;
          core.print(exception.message_);
        } else if (throw5_test.MyException2.is(e)) {
          let exception = e;
          i = 200;
          core.print(exception.message_);
        } else if (throw5_test.MyException1.is(e)) {
          let exception = e;
          i = 100;
          core.print(exception.message_);
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
      try {
        while (i < 10) {
          i++;
        }
        if (i > 0) {
          dart.throw(new throw5_test.MyException1("Test for MyException1 being thrown"));
        }
      } catch (e) {
        if (throw5_test.MyException3.is(e)) {
          let exception = e;
          i = 300;
          core.print(exception.message_);
        } else if (throw5_test.MyException2.is(e)) {
          let exception = e;
          i = 200;
          core.print(exception.message_);
        } else
          throw e;
      }

      return i;
    }
  };
  dart.setSignature(throw5_test.Helper, {
    statics: () => ({
      f1: dart.definiteFunctionType(core.int, [core.int]),
      func: dart.definiteFunctionType(core.int, [])
    }),
    names: ['f1', 'func']
  });
  throw5_test.Throw5Test = class Throw5Test extends core.Object {
    static testMain() {
      expect$.Expect.equals(900, throw5_test.Helper.f1(1));
    }
  };
  dart.setSignature(throw5_test.Throw5Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  throw5_test.main = function() {
    throw5_test.Throw5Test.testMain();
  };
  dart.fn(throw5_test.main, VoidTodynamic());
  // Exports:
  exports.throw5_test = throw5_test;
});
