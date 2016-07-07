dart_library.library('language/do_while_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__do_while_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const do_while_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  do_while_test.Helper = class Helper extends core.Object {
    static f1(b) {
      do
        return 1;
      while (dart.test(b));
      return 2;
    }
    static f2(b) {
      do {
        return 1;
      } while (dart.test(b));
      return 2;
    }
    static f3(b) {
      do
        ;
      while (dart.test(b));
      return 2;
    }
    static f4(b) {
      do {
      } while (dart.test(b));
      return 2;
    }
    static f5(n) {
      let i = 0;
      do {
        i++;
      } while (i < dart.notNull(n));
      return i;
    }
  };
  dart.setSignature(do_while_test.Helper, {
    statics: () => ({
      f1: dart.definiteFunctionType(core.int, [core.bool]),
      f2: dart.definiteFunctionType(core.int, [core.bool]),
      f3: dart.definiteFunctionType(core.int, [core.bool]),
      f4: dart.definiteFunctionType(core.int, [core.bool]),
      f5: dart.definiteFunctionType(core.int, [core.int])
    }),
    names: ['f1', 'f2', 'f3', 'f4', 'f5']
  });
  do_while_test.DoWhileTest = class DoWhileTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(1, do_while_test.Helper.f1(true));
      expect$.Expect.equals(1, do_while_test.Helper.f1(false));
      expect$.Expect.equals(1, do_while_test.Helper.f2(true));
      expect$.Expect.equals(1, do_while_test.Helper.f2(false));
      expect$.Expect.equals(2, do_while_test.Helper.f3(false));
      expect$.Expect.equals(2, do_while_test.Helper.f4(false));
      expect$.Expect.equals(1, do_while_test.Helper.f5(-2));
      expect$.Expect.equals(1, do_while_test.Helper.f5(-1));
      expect$.Expect.equals(1, do_while_test.Helper.f5(0));
      expect$.Expect.equals(1, do_while_test.Helper.f5(1));
      expect$.Expect.equals(2, do_while_test.Helper.f5(2));
      expect$.Expect.equals(3, do_while_test.Helper.f5(3));
    }
  };
  dart.setSignature(do_while_test.DoWhileTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  do_while_test.main = function() {
    do_while_test.DoWhileTest.testMain();
  };
  dart.fn(do_while_test.main, VoidTodynamic());
  // Exports:
  exports.do_while_test = do_while_test;
});
