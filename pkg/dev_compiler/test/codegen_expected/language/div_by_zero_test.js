dart_library.library('language/div_by_zero_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__div_by_zero_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const div_by_zero_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  div_by_zero_test.DivByZeroTest = class DivByZeroTest extends core.Object {
    static divBy(a, b) {
      let result = dart.notNull(a) / dart.notNull(b);
      return 1.0 * result;
    }
    static moustacheDivBy(a, b) {
      let val = null;
      try {
        val = (dart.notNull(a) / dart.notNull(b))[dartx.truncate]();
      } catch (e) {
        return true;
      }

      core.print(dart.str`Should not have gotten: ${val}`);
      return false;
    }
    static testMain() {
      expect$.Expect.isTrue(div_by_zero_test.DivByZeroTest.divBy(0, 0)[dartx.isNaN]);
      expect$.Expect.isTrue(div_by_zero_test.DivByZeroTest.moustacheDivBy(0, 0));
    }
  };
  dart.setSignature(div_by_zero_test.DivByZeroTest, {
    statics: () => ({
      divBy: dart.definiteFunctionType(core.double, [core.int, core.int]),
      moustacheDivBy: dart.definiteFunctionType(core.bool, [core.int, core.int]),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['divBy', 'moustacheDivBy', 'testMain']
  });
  div_by_zero_test.main = function() {
    div_by_zero_test.DivByZeroTest.testMain();
  };
  dart.fn(div_by_zero_test.main, VoidTodynamic());
  // Exports:
  exports.div_by_zero_test = div_by_zero_test;
});
