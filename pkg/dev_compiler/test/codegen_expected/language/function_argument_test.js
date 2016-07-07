dart_library.library('language/function_argument_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_argument_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_argument_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_argument_test.FunctionArgumentTest = class FunctionArgumentTest extends core.Object {
    static testMe(f) {
      return dart.dcall(f);
    }
    static testMain() {
      expect$.Expect.equals(42, function_argument_test.FunctionArgumentTest.testMe(dart.fn(() => 42, VoidToint())));
    }
  };
  dart.setSignature(function_argument_test.FunctionArgumentTest, {
    statics: () => ({
      testMe: dart.definiteFunctionType(dart.dynamic, [core.Function]),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testMe', 'testMain']
  });
  function_argument_test.main = function() {
    function_argument_test.FunctionArgumentTest.testMain();
  };
  dart.fn(function_argument_test.main, VoidTodynamic());
  // Exports:
  exports.function_argument_test = function_argument_test;
});
