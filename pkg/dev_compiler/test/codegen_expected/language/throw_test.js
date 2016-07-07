dart_library.library('language/throw_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__throw_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const throw_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  throw_test.MyException = class MyException extends core.Object {
    new(message_) {
      this.message_ = message_;
    }
  };
  dart.setSignature(throw_test.MyException, {
    constructors: () => ({new: dart.definiteFunctionType(throw_test.MyException, [core.String])})
  });
  throw_test.Helper = class Helper extends core.Object {
    static f1(i) {
      try {
        let j = null;
        j = throw_test.Helper.func();
        if (dart.notNull(j) > 0) {
          dart.throw(new throw_test.MyException("Test for exception being thrown"));
        }
      } catch (exception) {
        if (throw_test.MyException.is(exception)) {
          i = 100;
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
      let i = 0;
      while (i < 10) {
        i++;
      }
      return i;
    }
  };
  dart.setSignature(throw_test.Helper, {
    statics: () => ({
      f1: dart.definiteFunctionType(core.int, [core.int]),
      func: dart.definiteFunctionType(core.int, [])
    }),
    names: ['f1', 'func']
  });
  throw_test.ThrowTest = class ThrowTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(900, throw_test.Helper.f1(1));
    }
  };
  dart.setSignature(throw_test.ThrowTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  throw_test.main = function() {
    throw_test.ThrowTest.testMain();
  };
  dart.fn(throw_test.main, VoidTodynamic());
  // Exports:
  exports.throw_test = throw_test;
});
