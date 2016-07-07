dart_library.library('language/inference_list_or_null_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inference_list_or_null_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inference_list_or_null_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inference_list_or_null_test.list = null;
  inference_list_or_null_test.main = function() {
    if (new core.DateTime.now().millisecondsSinceEpoch == 0) inference_list_or_null_test.list = core.List.new(4);
    expect$.Expect.throws(dart.fn(() => core.print(dart.dindex(inference_list_or_null_test.list, 5)), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(inference_list_or_null_test.main, VoidTodynamic());
  // Exports:
  exports.inference_list_or_null_test = inference_list_or_null_test;
});
