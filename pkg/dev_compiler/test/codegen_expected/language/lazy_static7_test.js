dart_library.library('language/lazy_static7_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__lazy_static7_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const lazy_static7_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  lazy_static7_test.sideEffect = 0;
  dart.defineLazy(lazy_static7_test, {
    get x() {
      return dart.fn(() => {
        lazy_static7_test.sideEffect = dart.notNull(lazy_static7_test.sideEffect) + 1;
        return 499;
      }, VoidToint())();
    },
    set x(_) {}
  });
  lazy_static7_test.main = function() {
    if (dart.notNull(new core.DateTime.now().day) >= -1) {
      lazy_static7_test.x = 42;
    }
    expect$.Expect.equals(42, lazy_static7_test.x);
    expect$.Expect.equals(0, lazy_static7_test.sideEffect);
  };
  dart.fn(lazy_static7_test.main, VoidTodynamic());
  // Exports:
  exports.lazy_static7_test = lazy_static7_test;
});
