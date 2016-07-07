dart_library.library('language/lazy_static5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__lazy_static5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const lazy_static5_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic])))();
  let dynamicTodynamic$ = () => (dynamicTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicToFn = () => (dynamicToFn = dart.constFn(dart.definiteFunctionType(dynamicTodynamic(), [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(lazy_static5_test, {
    get x() {
      return dart.fn(t => dart.fn(u => dart.dsend(t, '+', u), dynamicTodynamic$()), dynamicToFn());
    }
  });
  lazy_static5_test.main = function() {
    expect$.Expect.equals(499, dart.dcall(dart.dcall(lazy_static5_test.x, 498), 1));
    expect$.Expect.equals(42, dart.dcall(dart.dcall(lazy_static5_test.x, 39), 3));
  };
  dart.fn(lazy_static5_test.main, VoidTodynamic());
  // Exports:
  exports.lazy_static5_test = lazy_static5_test;
});
