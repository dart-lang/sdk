dart_library.library('language/syncstar_yieldstar_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__syncstar_yieldstar_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const syncstar_yieldstar_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  syncstar_yieldstar_test.bar = function() {
    return dart.syncStar(function*() {
      let i = 1;
      let j = 1;
      while (true) {
        yield i;
        j = i + j;
        i = j - i;
      }
    }, dart.dynamic);
  };
  dart.fn(syncstar_yieldstar_test.bar, VoidTodynamic());
  syncstar_yieldstar_test.foo = function() {
    return dart.syncStar(function*() {
      yield* JSArrayOfint().of([1, 2, 3]);
      yield null;
      yield* core.Iterable.as(syncstar_yieldstar_test.bar());
    }, dart.dynamic);
  };
  dart.fn(syncstar_yieldstar_test.foo, VoidTodynamic());
  syncstar_yieldstar_test.main = function() {
    return dart.async(function*() {
      expect$.Expect.listEquals(JSArrayOfint().of([1, 2, 3, null, 1, 1, 2, 3, 5]), core.List._check(dart.dsend(dart.dsend(syncstar_yieldstar_test.foo(), 'take', 9), 'toList')));
    }, dart.dynamic);
  };
  dart.fn(syncstar_yieldstar_test.main, VoidTodynamic());
  // Exports:
  exports.syncstar_yieldstar_test = syncstar_yieldstar_test;
});
