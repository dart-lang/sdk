dart_library.library('lib/typed_data/int64_list_load_store_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int64_list_load_store_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int64_list_load_store_test = Object.create(null);
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  int64_list_load_store_test.testStoreLoad = function(l, z) {
    dart.dsetindex(l, 0, 9223372036854775807);
    dart.dsetindex(l, 1, 9223372036854775806);
    dart.dsetindex(l, 2, dart.dindex(l, 0));
    dart.dsetindex(l, 3, z);
    expect$.Expect.equals(dart.dindex(l, 0), 9223372036854775807);
    expect$.Expect.equals(dart.dindex(l, 1), 9223372036854775806);
    expect$.Expect.isTrue(dart.dsend(dart.dindex(l, 1), '<', dart.dindex(l, 0)));
    expect$.Expect.equals(dart.dindex(l, 2), dart.dindex(l, 0));
    expect$.Expect.equals(dart.dindex(l, 3), z);
  };
  dart.fn(int64_list_load_store_test.testStoreLoad, dynamicAnddynamicTovoid());
  int64_list_load_store_test.main = function() {
    let l = typed_data.Int64List.new(4);
    let zGood = 9223372036854775807;
    let zBad = false;
    for (let i = 0; i < 40; i++) {
      int64_list_load_store_test.testStoreLoad(l, zGood);
    }
    try {
      int64_list_load_store_test.testStoreLoad(l, zBad);
    } catch (_) {
    }

    for (let i = 0; i < 40; i++) {
      int64_list_load_store_test.testStoreLoad(l, zGood);
    }
  };
  dart.fn(int64_list_load_store_test.main, VoidTodynamic());
  // Exports:
  exports.int64_list_load_store_test = int64_list_load_store_test;
});
