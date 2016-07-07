dart_library.library('language/throw3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__throw3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const throw3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  throw3_test.MyException = class MyException extends core.Object {
    new(message) {
      if (message === void 0) message = "";
      this.message_ = message;
    }
  };
  dart.setSignature(throw3_test.MyException, {
    constructors: () => ({new: dart.definiteFunctionType(throw3_test.MyException, [], [core.String])})
  });
  throw3_test.Helper = class Helper extends core.Object {
    static f1(i) {
      try {
        let j = null;
        i = 100;
        i = throw3_test.Helper.func();
        i = 200;
      } catch (exception) {
        if (throw3_test.MyException.is(exception)) {
          i = 50;
          core.print(exception.message_);
        } else
          throw exception;
      }
 finally {
        i = dart.notNull(i) + 800;
      }
      return i;
    }
    static func() {
      try {
        let i = 0;
        while (i < 10) {
          i++;
        }
        if (i > 0) {
          dart.throw(new throw3_test.MyException("Test for exception being thrown"));
        }
      } catch (ex) {
        if (throw3_test.MyException.is(ex)) {
          core.print(ex.message_);
          throw ex;
        } else
          throw ex;
      }

      return 10;
    }
  };
  dart.setSignature(throw3_test.Helper, {
    statics: () => ({
      f1: dart.definiteFunctionType(core.int, [core.int]),
      func: dart.definiteFunctionType(core.int, [])
    }),
    names: ['f1', 'func']
  });
  throw3_test.Throw3Test = class Throw3Test extends core.Object {
    static testMain() {
      expect$.Expect.equals(850, throw3_test.Helper.f1(1));
    }
  };
  dart.setSignature(throw3_test.Throw3Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  throw3_test.main = function() {
    throw3_test.Throw3Test.testMain();
  };
  dart.fn(throw3_test.main, VoidTodynamic());
  // Exports:
  exports.throw3_test = throw3_test;
});
