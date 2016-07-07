dart_library.library('language/function_subtype_regression_ddc_588_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_regression_ddc_588_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_regression_ddc_588_test = Object.create(null);
  let ListOfInt2Int = () => (ListOfInt2Int = dart.constFn(core.List$(function_subtype_regression_ddc_588_test.Int2Int)))();
  let JSArrayOfFunction = () => (JSArrayOfFunction = dart.constFn(_interceptors.JSArray$(core.Function)))();
  let Int2IntTovoid = () => (Int2IntTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [function_subtype_regression_ddc_588_test.Int2Int])))();
  let ListOfInt2IntTovoid = () => (ListOfInt2IntTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfInt2Int()])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  function_subtype_regression_ddc_588_test.Int2Int = dart.typedef('Int2Int', () => dart.functionType(core.int, [core.int]));
  function_subtype_regression_ddc_588_test.foo = function(list) {
    list[dartx.forEach](dart.fn(f => core.print(f(42)), Int2IntTovoid()));
  };
  dart.fn(function_subtype_regression_ddc_588_test.foo, ListOfInt2IntTovoid());
  function_subtype_regression_ddc_588_test.main = function() {
    let l = JSArrayOfFunction().of([]);
    expect$.Expect.throws(dart.fn(() => function_subtype_regression_ddc_588_test.foo(ListOfInt2Int()._check(l)), VoidTovoid()), dart.fn(e => core.TypeError.is(e), dynamicTobool()));
  };
  dart.fn(function_subtype_regression_ddc_588_test.main, VoidTovoid());
  // Exports:
  exports.function_subtype_regression_ddc_588_test = function_subtype_regression_ddc_588_test;
});
