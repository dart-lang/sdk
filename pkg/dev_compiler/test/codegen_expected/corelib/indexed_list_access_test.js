dart_library.library('corelib/indexed_list_access_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__indexed_list_access_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const indexed_list_access_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  indexed_list_access_test.main = function() {
    indexed_list_access_test.checkList(core.List.new(10));
    let growable = core.List.new();
    growable[dartx.add](1);
    growable[dartx.add](1);
    indexed_list_access_test.checkList(growable);
  };
  dart.fn(indexed_list_access_test.main, VoidTodynamic());
  indexed_list_access_test.checkList = function(list) {
    expect$.Expect.isFalse(indexed_list_access_test.checkCatch(indexed_list_access_test.getIt, list, 1));
    expect$.Expect.isTrue(indexed_list_access_test.checkCatch(indexed_list_access_test.getIt, list, "hi"));
    expect$.Expect.isFalse(indexed_list_access_test.checkCatch(indexed_list_access_test.putIt, list, 1));
    expect$.Expect.isTrue(indexed_list_access_test.checkCatch(indexed_list_access_test.putIt, list, "hi"));
    for (let i = 0; i < 2000; i++) {
      indexed_list_access_test.putIt(list, 1);
      indexed_list_access_test.getIt(list, 1);
    }
    expect$.Expect.isTrue(indexed_list_access_test.checkCatch(indexed_list_access_test.getIt, list, "hi"));
    expect$.Expect.isTrue(indexed_list_access_test.checkCatch(indexed_list_access_test.putIt, list, "hi"));
  };
  dart.fn(indexed_list_access_test.checkList, dynamicTodynamic());
  indexed_list_access_test.checkCatch = function(f, list, index) {
    try {
      dart.dcall(f, list, index);
    } catch (e$) {
      if (core.ArgumentError.is(e$)) {
        let e = e$;
        return true;
      } else if (core.TypeError.is(e$)) {
        let t = e$;
        return true;
      } else
        throw e$;
    }

    return false;
  };
  dart.fn(indexed_list_access_test.checkCatch, dynamicAnddynamicAnddynamicTodynamic());
  indexed_list_access_test.getIt = function(a, i) {
    return dart.dindex(a, i);
  };
  dart.fn(indexed_list_access_test.getIt, dynamicAnddynamicTodynamic());
  indexed_list_access_test.putIt = function(a, i) {
    dart.dsetindex(a, i, null);
  };
  dart.fn(indexed_list_access_test.putIt, dynamicAnddynamicTodynamic());
  // Exports:
  exports.indexed_list_access_test = indexed_list_access_test;
});
