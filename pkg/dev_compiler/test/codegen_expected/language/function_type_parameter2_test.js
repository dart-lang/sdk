dart_library.library('language/function_type_parameter2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_type_parameter2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_type_parameter2_test = Object.create(null);
  let intToString = () => (intToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_parameter2_test.FunctionTypeParameterTest = class FunctionTypeParameterTest extends core.Object {
    static SetFormatter(fmt) {
      if (fmt === void 0) fmt = null;
      function_type_parameter2_test.FunctionTypeParameterTest.formatter = fmt;
    }
    static testMain() {
      expect$.Expect.equals(null, function_type_parameter2_test.FunctionTypeParameterTest.formatter);
      function_type_parameter2_test.FunctionTypeParameterTest.SetFormatter(dart.fn(i => dart.str`${i}`, intToString()));
      expect$.Expect.equals(false, null == function_type_parameter2_test.FunctionTypeParameterTest.formatter);
      expect$.Expect.equals("1234", dart.dcall(function_type_parameter2_test.FunctionTypeParameterTest.formatter, 1230 + 4));
      function_type_parameter2_test.FunctionTypeParameterTest.SetFormatter();
      expect$.Expect.equals(null, function_type_parameter2_test.FunctionTypeParameterTest.formatter);
    }
  };
  dart.setSignature(function_type_parameter2_test.FunctionTypeParameterTest, {
    statics: () => ({
      SetFormatter: dart.definiteFunctionType(dart.dynamic, [], [dart.functionType(core.String, [core.int])]),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['SetFormatter', 'testMain']
  });
  function_type_parameter2_test.FunctionTypeParameterTest.formatter = null;
  function_type_parameter2_test.main = function() {
    function_type_parameter2_test.FunctionTypeParameterTest.testMain();
  };
  dart.fn(function_type_parameter2_test.main, VoidTodynamic());
  // Exports:
  exports.function_type_parameter2_test = function_type_parameter2_test;
});
