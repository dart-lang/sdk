dart_library.library('corelib/map_keys2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_keys2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_keys2_test = Object.create(null);
  let MapOfString$int = () => (MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))();
  let MapOfString$bool = () => (MapOfString$bool = dart.constFn(core.Map$(core.String, core.bool)))();
  let IterableOfString = () => (IterableOfString = dart.constFn(core.Iterable$(core.String)))();
  let IterableOfbool = () => (IterableOfbool = dart.constFn(core.Iterable$(core.bool)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  map_keys2_test.main = function() {
    let map1 = dart.map({foo: 42, bar: 499}, core.String, core.int);
    let map2 = dart.map();
    let map3 = const$ || (const$ = dart.const(dart.map({foo: 42, bar: 499}, core.String, core.int)));
    let map4 = const$0 || (const$0 = dart.const(dart.map()));
    let map5 = MapOfString$int().new();
    map5[dartx.set]("foo", 43);
    map5[dartx.set]("bar", 500);
    let map6 = MapOfString$bool().new();
    expect$.Expect.isTrue(IterableOfString().is(map1[dartx.keys]));
    expect$.Expect.isTrue(IterableOfbool().is(map1[dartx.keys]));
    expect$.Expect.isTrue(IterableOfString().is(map2[dartx.keys]));
    expect$.Expect.isTrue(IterableOfbool().is(map2[dartx.keys]));
    expect$.Expect.isTrue(IterableOfString().is(map3[dartx.keys]));
    expect$.Expect.isTrue(IterableOfbool().is(map3[dartx.keys]));
    expect$.Expect.isTrue(IterableOfString().is(map4[dartx.keys]));
    expect$.Expect.isTrue(IterableOfbool().is(map4[dartx.keys]));
    expect$.Expect.isTrue(IterableOfString().is(map5[dartx.keys]));
    expect$.Expect.isFalse(IterableOfbool().is(map5[dartx.keys]));
    expect$.Expect.isTrue(IterableOfString().is(map6[dartx.keys]));
    expect$.Expect.isFalse(IterableOfbool().is(map6[dartx.keys]));
  };
  dart.fn(map_keys2_test.main, VoidTodynamic());
  // Exports:
  exports.map_keys2_test = map_keys2_test;
});
