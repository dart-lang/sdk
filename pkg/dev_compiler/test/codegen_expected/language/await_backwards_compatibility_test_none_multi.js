dart_library.library('language/await_backwards_compatibility_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__await_backwards_compatibility_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const await_backwards_compatibility_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.copyProperties(await_backwards_compatibility_test_none_multi, {
    get await() {
      return 4;
    }
  });
  await_backwards_compatibility_test_none_multi.test0 = function() {
    return dart.async(function*() {
      let x = (yield 7);
      expect$.Expect.equals(7, x);
    }, dart.dynamic);
  };
  dart.fn(await_backwards_compatibility_test_none_multi.test0, VoidTodynamic());
  await_backwards_compatibility_test_none_multi.test1 = function() {
    return dart.async(function*() {
      let x = (yield 9);
      expect$.Expect.equals(9, x);
    }, dart.dynamic);
  };
  dart.fn(await_backwards_compatibility_test_none_multi.test1, VoidTodynamic());
  await_backwards_compatibility_test_none_multi.test2 = function() {
    let y = await_backwards_compatibility_test_none_multi.await;
    expect$.Expect.equals(4, y);
  };
  dart.fn(await_backwards_compatibility_test_none_multi.test2, VoidTodynamic());
  await_backwards_compatibility_test_none_multi.test3 = function() {
    let await$ = 3;
    expect$.Expect.equals(3, await$);
  };
  dart.fn(await_backwards_compatibility_test_none_multi.test3, VoidTodynamic());
  await_backwards_compatibility_test_none_multi.main = function() {
    await_backwards_compatibility_test_none_multi.test0();
    await_backwards_compatibility_test_none_multi.test1();
    await_backwards_compatibility_test_none_multi.test2();
    await_backwards_compatibility_test_none_multi.test3();
  };
  dart.fn(await_backwards_compatibility_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.await_backwards_compatibility_test_none_multi = await_backwards_compatibility_test_none_multi;
});
