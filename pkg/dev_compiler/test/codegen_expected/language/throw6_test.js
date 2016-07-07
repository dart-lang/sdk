dart_library.library('language/throw6_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__throw6_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const throw6_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  throw6_test.MyException1 = class MyException1 extends core.Object {
    new(message) {
      if (message === void 0) message = "1";
      this.message_ = message;
    }
  };
  dart.setSignature(throw6_test.MyException1, {
    constructors: () => ({new: dart.definiteFunctionType(throw6_test.MyException1, [], [core.String])})
  });
  throw6_test.Helper = class Helper extends core.Object {
    new() {
      this.i = 0;
    }
    f1() {
      let j = 0;
      try {
        j = this.func();
      } catch (exception) {
        this.i = dart.notNull(this.i) + 100;
        core.print(dart.dload(exception, 'message_'));
      }
 finally {
        this.i = dart.notNull(this.i) + 1000;
      }
      return this.i;
    }
    func() {
      this.i = 0;
      try {
        while (dart.notNull(this.i) < 10) {
          this.i = dart.notNull(this.i) + 1;
        }
        if (dart.notNull(this.i) > 0) {
          dart.throw(new throw6_test.MyException1("Test for MyException1 being thrown"));
        }
      } finally {
        this.i = 800;
      }
      return this.i;
    }
  };
  dart.setSignature(throw6_test.Helper, {
    constructors: () => ({new: dart.definiteFunctionType(throw6_test.Helper, [])}),
    methods: () => ({
      f1: dart.definiteFunctionType(core.int, []),
      func: dart.definiteFunctionType(core.int, [])
    })
  });
  throw6_test.Throw6Test = class Throw6Test extends core.Object {
    static testMain() {
      expect$.Expect.equals(1900, new throw6_test.Helper().f1());
    }
  };
  dart.setSignature(throw6_test.Throw6Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  throw6_test.main = function() {
    throw6_test.Throw6Test.testMain();
  };
  dart.fn(throw6_test.main, VoidTodynamic());
  // Exports:
  exports.throw6_test = throw6_test;
});
