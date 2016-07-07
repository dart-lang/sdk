dart_library.library('corelib/map_values4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_values4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_values4_test = Object.create(null);
  let IterableOfString = () => (IterableOfString = dart.constFn(core.Iterable$(core.String)))();
  let IterableOfbool = () => (IterableOfbool = dart.constFn(core.Iterable$(core.bool)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  map_values4_test.main = function() {
    let map1 = dart.map([1, "42", 2, "499"], core.int, core.String);
    expect$.Expect.isTrue(IterableOfString().is(map1[dartx.values]));
    expect$.Expect.isFalse(IterableOfbool().is(map1[dartx.values]));
  };
  dart.fn(map_values4_test.main, VoidTodynamic());
  // Exports:
  exports.map_values4_test = map_values4_test;
});
