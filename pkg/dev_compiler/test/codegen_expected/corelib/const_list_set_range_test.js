dart_library.library('corelib/const_list_set_range_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_list_set_range_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_list_set_range_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let FunctionTovoid = () => (FunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Function])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let const$;
  let const$0;
  let const$1;
  const_list_set_range_test.main = function() {
    const_list_set_range_test.testImmutable(const$ || (const$ = dart.constList([], dart.dynamic)));
    const_list_set_range_test.testImmutable(const$0 || (const$0 = dart.constList([1], core.int)));
    const_list_set_range_test.testImmutable(const$1 || (const$1 = dart.constList([1, 2], core.int)));
  };
  dart.fn(const_list_set_range_test.main, VoidTodynamic());
  const_list_set_range_test.expectUOE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(const_list_set_range_test.expectUOE, FunctionTovoid());
  let const$2;
  let const$3;
  let const$4;
  let const$5;
  let const$6;
  const_list_set_range_test.testImmutable = function(list) {
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 0, const$2 || (const$2 = dart.constList([], dart.dynamic)));
    }, VoidTodynamic()));
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 1, const$3 || (const$3 = dart.constList([], dart.dynamic)), 1);
    }, VoidTodynamic()));
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 1, const$4 || (const$4 = dart.constList([], dart.dynamic)));
    }, VoidTodynamic()));
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 0, []);
    }, VoidTodynamic()));
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 1, [], 1);
    }, VoidTodynamic()));
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 1, []);
    }, VoidTodynamic()));
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 0, const$5 || (const$5 = dart.constList([1], core.int)));
    }, VoidTodynamic()));
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 1, const$6 || (const$6 = dart.constList([1], core.int)));
    }, VoidTodynamic()));
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 0, JSArrayOfint().of([1]));
    }, VoidTodynamic()));
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 1, JSArrayOfint().of([1]));
    }, VoidTodynamic()));
    const_list_set_range_test.expectUOE(dart.fn(() => {
      dart.dsend(list, 'setRange', 0, 1, JSArrayOfint().of([1]), 1);
    }, VoidTodynamic()));
  };
  dart.fn(const_list_set_range_test.testImmutable, dynamicTodynamic());
  // Exports:
  exports.const_list_set_range_test = const_list_set_range_test;
});
