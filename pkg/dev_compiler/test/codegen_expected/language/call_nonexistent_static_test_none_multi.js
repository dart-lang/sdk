dart_library.library('language/call_nonexistent_static_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__call_nonexistent_static_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const call_nonexistent_static_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], [VoidTovoid()])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  call_nonexistent_static_test_none_multi.C = class C extends core.Object {};
  call_nonexistent_static_test_none_multi.D = class D extends core.Object {};
  call_nonexistent_static_test_none_multi.expectNsme = function(fun) {
    if (fun === void 0) fun = null;
    if (fun != null) {
      expect$.Expect.throws(fun, dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
    }
  };
  dart.fn(call_nonexistent_static_test_none_multi.expectNsme, __Todynamic());
  let const$;
  call_nonexistent_static_test_none_multi.alwaysThrows = function() {
    dart.throw(new core.NoSuchMethodError(null, const$ || (const$ = dart.const(core.Symbol.new('foo'))), [], dart.map()));
  };
  dart.fn(call_nonexistent_static_test_none_multi.alwaysThrows, VoidTodynamic());
  call_nonexistent_static_test_none_multi.test01 = function() {
  };
  dart.fn(call_nonexistent_static_test_none_multi.test01, VoidTodynamic());
  call_nonexistent_static_test_none_multi.test02 = function() {
  };
  dart.fn(call_nonexistent_static_test_none_multi.test02, VoidTodynamic());
  call_nonexistent_static_test_none_multi.test03 = function() {
  };
  dart.fn(call_nonexistent_static_test_none_multi.test03, VoidTodynamic());
  call_nonexistent_static_test_none_multi.test04 = function() {
  };
  dart.fn(call_nonexistent_static_test_none_multi.test04, VoidTodynamic());
  call_nonexistent_static_test_none_multi.test05 = function() {
  };
  dart.fn(call_nonexistent_static_test_none_multi.test05, VoidTodynamic());
  call_nonexistent_static_test_none_multi.test06 = function() {
  };
  dart.fn(call_nonexistent_static_test_none_multi.test06, VoidTodynamic());
  call_nonexistent_static_test_none_multi.test07 = function() {
  };
  dart.fn(call_nonexistent_static_test_none_multi.test07, VoidTodynamic());
  call_nonexistent_static_test_none_multi.test08 = function() {
  };
  dart.fn(call_nonexistent_static_test_none_multi.test08, VoidTodynamic());
  call_nonexistent_static_test_none_multi.test09 = function() {
  };
  dart.fn(call_nonexistent_static_test_none_multi.test09, VoidTodynamic());
  call_nonexistent_static_test_none_multi.test10 = function() {
  };
  dart.fn(call_nonexistent_static_test_none_multi.test10, VoidTodynamic());
  call_nonexistent_static_test_none_multi.main = function() {
    call_nonexistent_static_test_none_multi.expectNsme(call_nonexistent_static_test_none_multi.alwaysThrows);
    call_nonexistent_static_test_none_multi.expectNsme();
    call_nonexistent_static_test_none_multi.expectNsme();
    call_nonexistent_static_test_none_multi.expectNsme();
    call_nonexistent_static_test_none_multi.expectNsme();
    call_nonexistent_static_test_none_multi.expectNsme();
    call_nonexistent_static_test_none_multi.expectNsme();
    call_nonexistent_static_test_none_multi.expectNsme();
    call_nonexistent_static_test_none_multi.expectNsme();
    call_nonexistent_static_test_none_multi.expectNsme();
    call_nonexistent_static_test_none_multi.expectNsme();
  };
  dart.fn(call_nonexistent_static_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.call_nonexistent_static_test_none_multi = call_nonexistent_static_test_none_multi;
});
