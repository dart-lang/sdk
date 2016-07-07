dart_library.library('language/while_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__while_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const while_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  while_test.Helper = class Helper extends core.Object {
    static f1(b) {
      while (dart.test(b))
        return 1;
      return 2;
    }
    static f2(b) {
      while (dart.test(b)) {
        return 1;
      }
      return 2;
    }
    static f3(n) {
      let i = 0;
      while (i < dart.notNull(n)) {
        i++;
      }
      return i;
    }
    static f4() {
      let i = 0;
      while (++i < 3) {
      }
      return i;
    }
  };
  dart.setSignature(while_test.Helper, {
    statics: () => ({
      f1: dart.definiteFunctionType(core.int, [core.bool]),
      f2: dart.definiteFunctionType(core.int, [core.bool]),
      f3: dart.definiteFunctionType(core.int, [core.int]),
      f4: dart.definiteFunctionType(core.int, [])
    }),
    names: ['f1', 'f2', 'f3', 'f4']
  });
  while_test.WhileTest = class WhileTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(1, while_test.Helper.f1(true));
      expect$.Expect.equals(2, while_test.Helper.f1(false));
      expect$.Expect.equals(1, while_test.Helper.f2(true));
      expect$.Expect.equals(2, while_test.Helper.f2(false));
      expect$.Expect.equals(0, while_test.Helper.f3(-2));
      expect$.Expect.equals(0, while_test.Helper.f3(-1));
      expect$.Expect.equals(0, while_test.Helper.f3(0));
      expect$.Expect.equals(1, while_test.Helper.f3(1));
      expect$.Expect.equals(2, while_test.Helper.f3(2));
      expect$.Expect.equals(3, while_test.Helper.f4());
    }
  };
  dart.setSignature(while_test.WhileTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  while_test.main = function() {
    while_test.WhileTest.testMain();
  };
  dart.fn(while_test.main, VoidTodynamic());
  // Exports:
  exports.while_test = while_test;
});
