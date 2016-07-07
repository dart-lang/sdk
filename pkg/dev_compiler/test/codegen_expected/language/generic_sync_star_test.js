dart_library.library('language/generic_sync_star_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_sync_star_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_sync_star_test = Object.create(null);
  let TToIterableOfT = () => (TToIterableOfT = dart.constFn(dart.definiteFunctionType(T => [core.Iterable$(T), [T]])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_sync_star_test.foo = function(T) {
    return x => {
      return dart.syncStar(function*(x) {
        for (let i = 0; i < 3; i++) {
          yield x;
        }
      }, T, x);
    };
  };
  dart.fn(generic_sync_star_test.foo, TToIterableOfT());
  generic_sync_star_test.main = function() {
    for (let x of generic_sync_star_test.foo(core.int)(1)) {
      expect$.Expect.equals(1, x);
    }
  };
  dart.fn(generic_sync_star_test.main, VoidTodynamic());
  // Exports:
  exports.generic_sync_star_test = generic_sync_star_test;
});
