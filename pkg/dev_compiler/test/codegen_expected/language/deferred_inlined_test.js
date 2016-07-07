dart_library.library('language/deferred_inlined_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deferred_inlined_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deferred_inlined_test = Object.create(null);
  const deferred_constraints_lib2 = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_inlined_test.libLoaded = false;
  deferred_inlined_test.main = function() {
    expect$.Expect.equals(88, deferred_inlined_test.heyhey());
    for (let i = 0; i < 30000; i++) {
      deferred_inlined_test.heyhey();
    }
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      deferred_inlined_test.libLoaded = true;
      expect$.Expect.equals(42, deferred_inlined_test.heyhey());
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_inlined_test.main, VoidTodynamic());
  deferred_inlined_test.heyhey = function() {
    return deferred_inlined_test.barbar();
  };
  dart.fn(deferred_inlined_test.heyhey, VoidTodynamic());
  deferred_inlined_test.barbar = function() {
    if (dart.test(deferred_inlined_test.libLoaded)) {
      return deferred_constraints_lib2.foo();
    }
    return 88;
  };
  dart.fn(deferred_inlined_test.barbar, VoidTodynamic());
  deferred_constraints_lib2.foo = function() {
    return 42;
  };
  dart.fn(deferred_constraints_lib2.foo, VoidTodynamic());
  deferred_constraints_lib2.C = class C extends core.Object {};
  // Exports:
  exports.deferred_inlined_test = deferred_inlined_test;
  exports.deferred_constraints_lib2 = deferred_constraints_lib2;
});
