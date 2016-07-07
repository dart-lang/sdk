dart_library.library('language/for_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__for_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const for_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  for_test.Helper = class Helper extends core.Object {
    static f1() {
      for (;;)
        return 1;
    }
    static f2(n) {
      let i = 0;
      for (; i < dart.notNull(core.num._check(n)); i++)
        ;
      return i;
    }
    static f3(n) {
      let i = 0;
      for (let j = 0; j < dart.notNull(n); j++)
        i = i + j + 1;
      return i;
    }
    static f4(n) {
      let i = 0;
      for (let stop = false; i < dart.notNull(core.num._check(n)) && !stop; i++) {
        if (i >= 5) {
          stop = true;
        }
      }
      return i;
    }
    static f5() {
      for_test.Helper.status = 0;
      for (let stop = false;;) {
        if (stop) {
          break;
        } else {
          stop = true;
          continue;
        }
      }
      for_test.Helper.status = 1;
    }
    static f6() {
      let i = 0;
      for (; ++i < 3;) {
      }
      return i;
    }
  };
  dart.setSignature(for_test.Helper, {
    statics: () => ({
      f1: dart.definiteFunctionType(core.int, []),
      f2: dart.definiteFunctionType(core.int, [dart.dynamic]),
      f3: dart.definiteFunctionType(core.int, [core.int]),
      f4: dart.definiteFunctionType(core.int, [dart.dynamic]),
      f5: dart.definiteFunctionType(dart.void, []),
      f6: dart.definiteFunctionType(core.int, [])
    }),
    names: ['f1', 'f2', 'f3', 'f4', 'f5', 'f6']
  });
  for_test.Helper.status = null;
  for_test.ForTest = class ForTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(1, for_test.Helper.f1());
      expect$.Expect.equals(0, for_test.Helper.f2(-1));
      expect$.Expect.equals(0, for_test.Helper.f2(0));
      expect$.Expect.equals(10, for_test.Helper.f2(10));
      expect$.Expect.equals(0, for_test.Helper.f3(-1));
      expect$.Expect.equals(0, for_test.Helper.f3(0));
      expect$.Expect.equals(1, for_test.Helper.f3(1));
      expect$.Expect.equals(3, for_test.Helper.f3(2));
      expect$.Expect.equals(6, for_test.Helper.f3(3));
      expect$.Expect.equals(10, for_test.Helper.f3(4));
      expect$.Expect.equals(0, for_test.Helper.f4(-1));
      expect$.Expect.equals(0, for_test.Helper.f4(0));
      expect$.Expect.equals(1, for_test.Helper.f4(1));
      expect$.Expect.equals(6, for_test.Helper.f4(6));
      expect$.Expect.equals(6, for_test.Helper.f4(10));
      for_test.Helper.f5();
      expect$.Expect.equals(1, for_test.Helper.status);
      expect$.Expect.equals(3, for_test.Helper.f6());
    }
  };
  dart.setSignature(for_test.ForTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  for_test.main = function() {
    for_test.ForTest.testMain();
  };
  dart.fn(for_test.main, VoidTodynamic());
  // Exports:
  exports.for_test = for_test;
});
