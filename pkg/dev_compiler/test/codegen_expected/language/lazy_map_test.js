dart_library.library('language/lazy_map_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__lazy_map_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const lazy_map_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(lazy_map_test, {
    get data() {
      return dart.map({a: 'a'}, core.String, core.String);
    },
    set data(_) {}
  });
  lazy_map_test.main = function() {
    expect$.Expect.equals('a', lazy_map_test.data[dartx.get]('a'));
  };
  dart.fn(lazy_map_test.main, VoidTodynamic());
  // Exports:
  exports.lazy_map_test = lazy_map_test;
});
