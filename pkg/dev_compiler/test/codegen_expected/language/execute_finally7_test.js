dart_library.library('language/execute_finally7_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__execute_finally7_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const execute_finally7_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  execute_finally7_test.MyException = class MyException extends core.Object {
    new(message) {
      this.message_ = message;
    }
  };
  dart.setSignature(execute_finally7_test.MyException, {
    constructors: () => ({new: dart.definiteFunctionType(execute_finally7_test.MyException, [core.String])})
  });
  execute_finally7_test.Helper = class Helper extends core.Object {
    static f1(k) {
      let b = null;
      try {
        let a = core.List.new(10);
        let i = 0;
        while (i < 10) {
          let j = i;
          a[dartx.set](i, dart.fn(() => {
            if (j == 5) {
              dart.throw(new execute_finally7_test.MyException("Test for exception being thrown"));
            }
            k = dart.notNull(k) + 10;
            return j;
          }, VoidToint()));
          if (i == 0) {
            b = a[dartx.get](i);
          }
          i++;
        }
        for (let i = 0; i < 10; i++) {
          dart.dcall(a[dartx.get](i));
        }
      } catch (exception) {
        if (execute_finally7_test.MyException.is(exception)) {
          k = dart.notNull(k) + 100;
          core.print(exception.message_);
          dart.dcall(b);
        } else
          throw exception;
      }
 finally {
        k = dart.notNull(k) + 1000;
        dart.dcall(b);
      }
      return k;
    }
  };
  dart.setSignature(execute_finally7_test.Helper, {
    statics: () => ({f1: dart.definiteFunctionType(core.int, [core.int])}),
    names: ['f1']
  });
  execute_finally7_test.ExecuteFinally7Test = class ExecuteFinally7Test extends core.Object {
    static testMain() {
      expect$.Expect.equals(1171, execute_finally7_test.Helper.f1(1));
    }
  };
  dart.setSignature(execute_finally7_test.ExecuteFinally7Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  execute_finally7_test.main = function() {
    execute_finally7_test.ExecuteFinally7Test.testMain();
  };
  dart.fn(execute_finally7_test.main, VoidTodynamic());
  // Exports:
  exports.execute_finally7_test = execute_finally7_test;
});
