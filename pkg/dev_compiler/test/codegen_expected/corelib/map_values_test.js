dart_library.library('corelib/map_values_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_values_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_values_test = Object.create(null);
  let MapOfString$int = () => (MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))();
  let MapOfString$bool = () => (MapOfString$bool = dart.constFn(core.Map$(core.String, core.bool)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  map_values_test.main = function() {
    let map1 = dart.map({foo: 42, bar: 499}, core.String, core.int);
    let map2 = dart.map();
    let map3 = const$ || (const$ = dart.const(dart.map({foo: 42, bar: 499}, core.String, core.int)));
    let map4 = const$0 || (const$0 = dart.const(dart.map()));
    let map5 = MapOfString$int().new();
    map5[dartx.set]("foo", 43);
    map5[dartx.set]("bar", 500);
    let map6 = MapOfString$bool().new();
    expect$.Expect.isTrue(core.Iterable.is(map1[dartx.values]));
    expect$.Expect.isFalse(core.List.is(map1[dartx.values]));
    expect$.Expect.equals(2, map1[dartx.values][dartx.length]);
    expect$.Expect.equals(42, map1[dartx.values][dartx.first]);
    expect$.Expect.equals(499, map1[dartx.values][dartx.last]);
    expect$.Expect.isTrue(core.Iterable.is(map2[dartx.values]));
    expect$.Expect.isFalse(core.List.is(map2[dartx.values]));
    expect$.Expect.equals(0, map2[dartx.values][dartx.length]);
    expect$.Expect.isTrue(core.Iterable.is(map3[dartx.values]));
    expect$.Expect.isFalse(core.List.is(map3[dartx.values]));
    expect$.Expect.equals(2, map3[dartx.values][dartx.length]);
    expect$.Expect.equals(42, map3[dartx.values][dartx.first]);
    expect$.Expect.equals(499, map3[dartx.values][dartx.last]);
    expect$.Expect.isTrue(core.Iterable.is(map4[dartx.values]));
    expect$.Expect.isFalse(core.List.is(map4[dartx.values]));
    expect$.Expect.equals(0, map4[dartx.values][dartx.length]);
    expect$.Expect.isTrue(core.Iterable.is(map5[dartx.values]));
    expect$.Expect.isFalse(core.List.is(map5[dartx.values]));
    expect$.Expect.equals(2, map5[dartx.values][dartx.length]);
    expect$.Expect.isTrue(map5[dartx.values][dartx.first] == 43 || map5[dartx.values][dartx.first] == 500);
    expect$.Expect.isTrue(map5[dartx.values][dartx.last] == 43 || map5[dartx.values][dartx.last] == 500);
    expect$.Expect.notEquals(map5[dartx.values][dartx.first], map5[dartx.values][dartx.last]);
    expect$.Expect.isTrue(core.Iterable.is(map6[dartx.values]));
    expect$.Expect.isFalse(core.List.is(map6[dartx.values]));
    expect$.Expect.equals(0, map6[dartx.values][dartx.length]);
  };
  dart.fn(map_values_test.main, VoidTodynamic());
  // Exports:
  exports.map_values_test = map_values_test;
});
