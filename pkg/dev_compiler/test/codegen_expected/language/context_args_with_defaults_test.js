dart_library.library('language/context_args_with_defaults_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__context_args_with_defaults_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const context_args_with_defaults_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  context_args_with_defaults_test.ContextArgsWithDefaultsTest = class ContextArgsWithDefaultsTest extends core.Object {
    static testMain() {
      dart.dcall(context_args_with_defaults_test.ContextArgsWithDefaultsTest.crasher(1, 'foo'));
    }
    static crasher(fixed, optional) {
      if (optional === void 0) optional = '';
      return dart.fn(() => {
        expect$.Expect.equals(1, fixed);
        expect$.Expect.equals('foo', optional);
      }, VoidTodynamic());
    }
  };
  dart.setSignature(context_args_with_defaults_test.ContextArgsWithDefaultsTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.void, []),
      crasher: dart.definiteFunctionType(dart.dynamic, [core.int], [core.String])
    }),
    names: ['testMain', 'crasher']
  });
  context_args_with_defaults_test.main = function() {
    context_args_with_defaults_test.ContextArgsWithDefaultsTest.testMain();
  };
  dart.fn(context_args_with_defaults_test.main, VoidTodynamic());
  // Exports:
  exports.context_args_with_defaults_test = context_args_with_defaults_test;
});
