dart_library.library('language/lazy_static2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__lazy_static2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const lazy_static2_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(lazy_static2_test, {
    get x() {
      return dart.fn(t => dart.dsend(t, '+', 1), dynamicTodynamic());
    }
  });
  lazy_static2_test.main = function() {
    expect$.Expect.equals(499, dart.dcall(lazy_static2_test.x, 498));
    expect$.Expect.equals(42, dart.dcall(lazy_static2_test.x, 41));
  };
  dart.fn(lazy_static2_test.main, VoidTodynamic());
  // Exports:
  exports.lazy_static2_test = lazy_static2_test;
});
