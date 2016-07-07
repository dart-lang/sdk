dart_library.library('corelib/const_list_remove_range_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_list_remove_range_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_list_remove_range_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let FunctionTovoid = () => (FunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Function])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let const$;
  let const$0;
  let const$1;
  const_list_remove_range_test.main = function() {
    const_list_remove_range_test.testImmutable(const$ || (const$ = dart.constList([], dart.dynamic)));
    const_list_remove_range_test.testImmutable(const$0 || (const$0 = dart.constList([1], core.int)));
    const_list_remove_range_test.testImmutable(const$1 || (const$1 = dart.constList([1, 2], core.int)));
  };
  dart.fn(const_list_remove_range_test.main, VoidTodynamic());
  const_list_remove_range_test.expectUOE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(const_list_remove_range_test.expectUOE, FunctionTovoid());
  const_list_remove_range_test.testImmutable = function(list) {
    const_list_remove_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'removeRange', 0, 0);
    }, VoidTodynamic()));
    const_list_remove_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'removeRange', 0, 1);
    }, VoidTodynamic()));
    const_list_remove_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'removeRange', -1, 1);
    }, VoidTodynamic()));
  };
  dart.fn(const_list_remove_range_test.testImmutable, dynamicTodynamic());
  // Exports:
  exports.const_list_remove_range_test = const_list_remove_range_test;
});
