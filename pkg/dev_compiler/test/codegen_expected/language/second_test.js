dart_library.library('language/second_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__second_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const second_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  second_test.Helper = class Helper extends core.Object {
    static empty() {}
    static foo() {
      return 42;
    }
  };
  dart.setSignature(second_test.Helper, {
    statics: () => ({
      empty: dart.definiteFunctionType(dart.dynamic, []),
      foo: dart.definiteFunctionType(core.int, [])
    }),
    names: ['empty', 'foo']
  });
  second_test.SecondTest = class SecondTest extends core.Object {
    static testMain() {
      second_test.Helper.empty();
      expect$.Expect.equals(42, second_test.Helper.foo());
    }
  };
  dart.setSignature(second_test.SecondTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  second_test.main = function() {
    second_test.SecondTest.testMain();
  };
  dart.fn(second_test.main, VoidTodynamic());
  // Exports:
  exports.second_test = second_test;
});
