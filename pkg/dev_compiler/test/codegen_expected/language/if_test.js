dart_library.library('language/if_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__if_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const if_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  if_test.Helper = class Helper extends core.Object {
    static f0(b) {
      if (dart.test(b)) ;
      if (dart.test(b))
        ;
      else
        ;
      if (dart.test(b)) {
      }
      if (dart.test(b)) {
      } else {
      }
      return 0;
    }
    static f1(b) {
      if (dart.test(b))
        return 1;
      else
        return 2;
    }
    static f2(b) {
      if (dart.test(b)) {
        return 1;
      } else {
        return 2;
      }
    }
    static f3(b) {
      if (dart.test(b)) return 1;
      return 2;
    }
    static f4(b) {
      if (dart.test(b)) {
        return 1;
      }
      return 2;
    }
    static f5(b) {
      if (!dart.test(b)) {
        return 1;
      }
      return 2;
    }
    static f6(a, b) {
      if (dart.test(a) || dart.test(b)) {
        return 1;
      }
      return 2;
    }
    static f7(a, b) {
      if (dart.test(a) && dart.test(b)) {
        return 1;
      }
      return 2;
    }
  };
  dart.setSignature(if_test.Helper, {
    statics: () => ({
      f0: dart.definiteFunctionType(core.int, [core.bool]),
      f1: dart.definiteFunctionType(core.int, [core.bool]),
      f2: dart.definiteFunctionType(core.int, [core.bool]),
      f3: dart.definiteFunctionType(core.int, [core.bool]),
      f4: dart.definiteFunctionType(core.int, [core.bool]),
      f5: dart.definiteFunctionType(core.int, [core.bool]),
      f6: dart.definiteFunctionType(core.int, [core.bool, core.bool]),
      f7: dart.definiteFunctionType(core.int, [core.bool, core.bool])
    }),
    names: ['f0', 'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7']
  });
  if_test.IfTest = class IfTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(0, if_test.Helper.f0(true));
      expect$.Expect.equals(1, if_test.Helper.f1(true));
      expect$.Expect.equals(2, if_test.Helper.f1(false));
      expect$.Expect.equals(1, if_test.Helper.f2(true));
      expect$.Expect.equals(2, if_test.Helper.f2(false));
      expect$.Expect.equals(1, if_test.Helper.f3(true));
      expect$.Expect.equals(2, if_test.Helper.f3(false));
      expect$.Expect.equals(1, if_test.Helper.f4(true));
      expect$.Expect.equals(2, if_test.Helper.f4(false));
      expect$.Expect.equals(2, if_test.Helper.f5(true));
      expect$.Expect.equals(1, if_test.Helper.f5(false));
      expect$.Expect.equals(1, if_test.Helper.f6(true, true));
      expect$.Expect.equals(1, if_test.Helper.f6(true, false));
      expect$.Expect.equals(1, if_test.Helper.f6(false, true));
      expect$.Expect.equals(2, if_test.Helper.f6(false, false));
      expect$.Expect.equals(1, if_test.Helper.f7(true, true));
      expect$.Expect.equals(2, if_test.Helper.f7(true, false));
      expect$.Expect.equals(2, if_test.Helper.f7(false, true));
      expect$.Expect.equals(2, if_test.Helper.f7(false, false));
    }
  };
  dart.setSignature(if_test.IfTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  if_test.main = function() {
    if_test.IfTest.testMain();
  };
  dart.fn(if_test.main, VoidTodynamic());
  // Exports:
  exports.if_test = if_test;
});
