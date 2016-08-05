dart_library.library('language/syncstar_less_than_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__syncstar_less_than_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const syncstar_less_than_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToIterableOfint = () => (VoidToIterableOfint = dart.constFn(dart.definiteFunctionType(IterableOfint(), [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  syncstar_less_than_test.confuse = function(x) {
    return JSArrayOfObject().of([1, 'x', true, null, x])[dartx.last];
  };
  dart.fn(syncstar_less_than_test.confuse, dynamicTodynamic());
  syncstar_less_than_test.foo = function() {
    return dart.syncStar(function*() {
      let a = syncstar_less_than_test.confuse(1);
      if (dart.test(dart.dsend(a, '<', 10))) {
        yield 2;
      }
    }, core.int);
  };
  dart.fn(syncstar_less_than_test.foo, VoidToIterableOfint());
  syncstar_less_than_test.main = function() {
    expect$.Expect.listEquals(syncstar_less_than_test.foo()[dartx.toList](), JSArrayOfint().of([2]));
  };
  dart.fn(syncstar_less_than_test.main, VoidTodynamic());
  // Exports:
  exports.syncstar_less_than_test = syncstar_less_than_test;
});
