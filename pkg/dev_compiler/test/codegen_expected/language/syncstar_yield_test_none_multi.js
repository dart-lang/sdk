dart_library.library('language/syncstar_yield_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__syncstar_yield_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const syncstar_yield_test_none_multi = Object.create(null);
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidToIterableOfint = () => (VoidToIterableOfint = dart.constFn(dart.definiteFunctionType(IterableOfint(), [])))();
  let dynamicToIterableOfint = () => (dynamicToIterableOfint = dart.constFn(dart.definiteFunctionType(IterableOfint(), [dart.dynamic])))();
  let intToIterableOfint = () => (intToIterableOfint = dart.constFn(dart.definiteFunctionType(IterableOfint(), [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  syncstar_yield_test_none_multi.foo1 = function() {
    return dart.syncStar(function*() {
      yield 1;
    }, core.int);
  };
  dart.fn(syncstar_yield_test_none_multi.foo1, VoidToIterableOfint());
  syncstar_yield_test_none_multi.foo2 = function(p) {
    return dart.syncStar(function*(p) {
      let t = false;
      yield null;
      while (true) {
        a:
          for (let i = 0; i < dart.notNull(core.num._check(p)); i++) {
            if (!t) {
              for (let j = 0; j < 3; j++) {
                yield -1;
                t = true;
                break a;
              }
            }
            yield i;
          }
      }
    }, core.int, p);
  };
  dart.fn(syncstar_yield_test_none_multi.foo2, dynamicToIterableOfint());
  syncstar_yield_test_none_multi.foo3 = function(p) {
    return dart.syncStar(function*(p) {
      let i = 0;
      i++;
      p = dart.notNull(p) + 1;
      yield dart.notNull(p) + i;
    }, core.int, p);
  };
  dart.fn(syncstar_yield_test_none_multi.foo3, intToIterableOfint());
  syncstar_yield_test_none_multi.main = function() {
    expect$.Expect.listEquals(JSArrayOfint().of([1]), syncstar_yield_test_none_multi.foo1()[dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([null, -1, 0, 1, 2, 3, 0, 1, 2, 3]), syncstar_yield_test_none_multi.foo2(4)[dartx.take](10)[dartx.toList]());
    let t = syncstar_yield_test_none_multi.foo3(0);
    let it1 = t[dartx.iterator];
    it1.moveNext();
    expect$.Expect.equals(2, it1.current);
    expect$.Expect.isFalse(it1.moveNext());
    expect$.Expect.isFalse(it1.moveNext());
  };
  dart.fn(syncstar_yield_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.syncstar_yield_test_none_multi = syncstar_yield_test_none_multi;
});
