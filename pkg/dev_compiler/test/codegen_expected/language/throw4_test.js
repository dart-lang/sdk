dart_library.library('language/throw4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__throw4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const throw4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  throw4_test.MyException1 = class MyException1 extends core.Object {
    new(message) {
      if (message === void 0) message = "1";
      this.message_ = message;
    }
  };
  dart.setSignature(throw4_test.MyException1, {
    constructors: () => ({new: dart.definiteFunctionType(throw4_test.MyException1, [], [core.String])})
  });
  throw4_test.MyException2 = class MyException2 extends core.Object {
    new(message) {
      if (message === void 0) message = "2";
      this.message_ = message;
    }
  };
  dart.setSignature(throw4_test.MyException2, {
    constructors: () => ({new: dart.definiteFunctionType(throw4_test.MyException2, [], [core.String])})
  });
  throw4_test.MyException3 = class MyException3 extends core.Object {
    new(message) {
      if (message === void 0) message = "3";
      this.message_ = message;
    }
  };
  dart.setSignature(throw4_test.MyException3, {
    constructors: () => ({new: dart.definiteFunctionType(throw4_test.MyException3, [], [core.String])})
  });
  throw4_test.Helper = class Helper extends core.Object {
    new() {
      this.i = 0;
    }
    f1() {
      let j = 0;
      try {
        j = this.func();
      } catch (e) {
        if (throw4_test.MyException3.is(e)) {
          let exception = e;
          this.i = dart.notNull(this.i) + 300;
          core.print(exception.message_);
        } else if (throw4_test.MyException2.is(e)) {
          let exception = e;
          this.i = dart.notNull(this.i) + 200;
          core.print(exception.message_);
        } else if (throw4_test.MyException1.is(e)) {
          let exception = e;
          this.i = dart.notNull(this.i) + 100;
          core.print(exception.message_);
        } else
          throw e;
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
          dart.throw(new throw4_test.MyException1("Test for MyException1 being thrown"));
        }
      } catch (e) {
        if (throw4_test.MyException3.is(e)) {
          let exception = e;
          this.i = 300;
          core.print(exception.message_);
        } else if (throw4_test.MyException2.is(e)) {
          let exception = e;
          this.i = 200;
          core.print(exception.message_);
        } else
          throw e;
      }
 finally {
        this.i = 800;
      }
      return this.i;
    }
  };
  dart.setSignature(throw4_test.Helper, {
    constructors: () => ({new: dart.definiteFunctionType(throw4_test.Helper, [])}),
    methods: () => ({
      f1: dart.definiteFunctionType(core.int, []),
      func: dart.definiteFunctionType(core.int, [])
    })
  });
  throw4_test.Throw4Test = class Throw4Test extends core.Object {
    static testMain() {
      expect$.Expect.equals(1900, new throw4_test.Helper().f1());
    }
  };
  dart.setSignature(throw4_test.Throw4Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  throw4_test.main = function() {
    throw4_test.Throw4Test.testMain();
  };
  dart.fn(throw4_test.main, VoidTodynamic());
  // Exports:
  exports.throw4_test = throw4_test;
});
