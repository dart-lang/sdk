dart_library.library('language/native_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__native_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const native_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  native_test.Helper = class Helper extends core.Object {
    static foo(i) {
      return dart.notNull(i) + 10;
    }
  };
  dart.setSignature(native_test.Helper, {
    statics: () => ({foo: dart.definiteFunctionType(core.int, [core.int])}),
    names: ['foo']
  });
  native_test.NativeTest = class NativeTest extends core.Object {
    static testMain() {
      let i = 10;
      let result = 10 + 10 + 10;
      i = native_test.Helper.foo(dart.notNull(i) + 10);
      core.print(dart.str`${i} is result.`);
      expect$.Expect.equals(i, result);
    }
  };
  dart.setSignature(native_test.NativeTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  native_test.main = function() {
    native_test.NativeTest.testMain();
  };
  dart.fn(native_test.main, VoidTodynamic());
  // Exports:
  exports.native_test = native_test;
});
