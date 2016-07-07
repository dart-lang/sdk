dart_library.library('language/async_await_syntax_test_b12g_multi', null, /* Imports */[
  'dart_sdk'
], function load__async_await_syntax_test_b12g_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_await_syntax_test_b12g_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  async_await_syntax_test_b12g_multi.yield = 0;
  async_await_syntax_test_b12g_multi.await = 0;
  dart.copyProperties(async_await_syntax_test_b12g_multi, {
    get st() {
      return async.Stream.fromIterable([]);
    }
  });
  async_await_syntax_test_b12g_multi.B = class B extends core.Object {};
  async_await_syntax_test_b12g_multi.C = class C extends async_await_syntax_test_b12g_multi.B {
    new() {
    }
    get b12g() {
      return dart.async(function*() {
        return null;
      }, dart.dynamic);
    }
  };
  dart.setSignature(async_await_syntax_test_b12g_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(async_await_syntax_test_b12g_multi.C, [])})
  });
  async_await_syntax_test_b12g_multi.method1 = function() {
  };
  dart.fn(async_await_syntax_test_b12g_multi.method1, VoidTodynamic());
  async_await_syntax_test_b12g_multi.method2 = function() {
  };
  dart.fn(async_await_syntax_test_b12g_multi.method2, VoidTodynamic());
  async_await_syntax_test_b12g_multi.main = function() {
    let a = null;
    let c = new async_await_syntax_test_b12g_multi.C();
    a = c.b12g;
    async_await_syntax_test_b12g_multi.method1();
    async_await_syntax_test_b12g_multi.method2();
  };
  dart.fn(async_await_syntax_test_b12g_multi.main, VoidTovoid());
  // Exports:
  exports.async_await_syntax_test_b12g_multi = async_await_syntax_test_b12g_multi;
});
