dart_library.library('corelib/map_keys_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_keys_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_keys_test = Object.create(null);
  let MapOfString$int = () => (MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))();
  let MapOfString$bool = () => (MapOfString$bool = dart.constFn(core.Map$(core.String, core.bool)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  map_keys_test.main = function() {
    let map1 = dart.map({foo: 42, bar: 499});
    let map2 = dart.map();
    let map3 = const$ || (const$ = dart.const(dart.map({foo: 42, bar: 499})));
    let map4 = const$0 || (const$0 = dart.const(dart.map()));
    let map5 = MapOfString$int().new();
    map5[dartx.set]("foo", 43);
    map5[dartx.set]("bar", 500);
    let map6 = MapOfString$bool().new();
    expect$.Expect.isTrue(core.Iterable.is(map1[dartx.keys]));
    expect$.Expect.isFalse(core.List.is(map1[dartx.keys]));
    expect$.Expect.equals(2, map1[dartx.keys][dartx.length]);
    expect$.Expect.equals("foo", map1[dartx.keys][dartx.first]);
    expect$.Expect.equals("bar", map1[dartx.keys][dartx.last]);
    expect$.Expect.isTrue(core.Iterable.is(map2[dartx.keys]));
    expect$.Expect.isFalse(core.List.is(map2[dartx.keys]));
    expect$.Expect.equals(0, map2[dartx.keys][dartx.length]);
    expect$.Expect.isTrue(core.Iterable.is(map3[dartx.keys]));
    expect$.Expect.isFalse(core.List.is(map3[dartx.keys]));
    expect$.Expect.equals(2, map3[dartx.keys][dartx.length]);
    expect$.Expect.equals("foo", map3[dartx.keys][dartx.first]);
    expect$.Expect.equals("bar", map3[dartx.keys][dartx.last]);
    expect$.Expect.isTrue(core.Iterable.is(map4[dartx.keys]));
    expect$.Expect.isFalse(core.List.is(map4[dartx.keys]));
    expect$.Expect.equals(0, map4[dartx.keys][dartx.length]);
    expect$.Expect.isTrue(core.Iterable.is(map5[dartx.keys]));
    expect$.Expect.isFalse(core.List.is(map5[dartx.keys]));
    expect$.Expect.equals(2, map5[dartx.keys][dartx.length]);
    expect$.Expect.isTrue(map5[dartx.keys][dartx.first] == "foo" || map5[dartx.keys][dartx.first] == "bar");
    expect$.Expect.isTrue(map5[dartx.keys][dartx.last] == "foo" || map5[dartx.keys][dartx.last] == "bar");
    expect$.Expect.notEquals(map5[dartx.keys][dartx.first], map5[dartx.keys][dartx.last]);
    expect$.Expect.isTrue(core.Iterable.is(map6[dartx.keys]));
    expect$.Expect.isFalse(core.List.is(map6[dartx.keys]));
    expect$.Expect.equals(0, map6[dartx.keys][dartx.length]);
  };
  dart.fn(map_keys_test.main, VoidTodynamic());
  // Exports:
  exports.map_keys_test = map_keys_test;
});
