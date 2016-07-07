dart_library.library('corelib/apply_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__apply_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const apply_test = Object.create(null);
  const symbol_map_helper = Object.create(null);
  let MapOfString$dynamic = () => (MapOfString$dynamic = dart.constFn(core.Map$(core.String, dart.dynamic)))();
  let MapOfSymbol$dynamic = () => (MapOfSymbol$dynamic = dart.constFn(core.Map$(core.Symbol, dart.dynamic)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let __Toint = () => (__Toint = dart.constFn(dart.definiteFunctionType(core.int, [], {a: core.int})))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let int__Toint = () => (int__Toint = dart.constFn(dart.definiteFunctionType(core.int, [core.int], {a: core.int})))();
  let intAndintToint = () => (intAndintToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int, core.int])))();
  let intAndint__Toint = () => (intAndint__Toint = dart.constFn(dart.definiteFunctionType(core.int, [core.int, core.int], {a: core.int})))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAnddynamicTovoid = () => (StringAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, dart.dynamic])))();
  let MapOfString$dynamicToMapOfSymbol$dynamic = () => (MapOfString$dynamicToMapOfSymbol$dynamic = dart.constFn(dart.definiteFunctionType(MapOfSymbol$dynamic(), [MapOfString$dynamic()])))();
  apply_test.test0 = function() {
    return 42;
  };
  dart.fn(apply_test.test0, VoidToint());
  apply_test.test0a = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    return 37 + dart.notNull(a);
  };
  dart.fn(apply_test.test0a, __Toint());
  apply_test.test1 = function(i) {
    return dart.notNull(i) + 1;
  };
  dart.fn(apply_test.test1, intToint());
  apply_test.test1a = function(i, opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    return dart.notNull(i) + dart.notNull(a);
  };
  dart.fn(apply_test.test1a, int__Toint());
  apply_test.test2 = function(i, j) {
    return dart.notNull(i) + dart.notNull(j);
  };
  dart.fn(apply_test.test2, intAndintToint());
  apply_test.test2a = function(i, j, opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    return dart.notNull(i) + dart.notNull(j) + dart.notNull(a);
  };
  dart.fn(apply_test.test2a, intAndint__Toint());
  apply_test.C = class C extends core.Object {
    new() {
      this.x = 10;
    }
    foo(y) {
      return dart.asInt(dart.notNull(this.x) + dart.notNull(core.num._check(y)));
    }
  };
  dart.setSignature(apply_test.C, {
    methods: () => ({foo: dart.definiteFunctionType(core.int, [dart.dynamic])})
  });
  apply_test.Callable = dart.callableClass(function Callable(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class Callable extends core.Object {
    call(x, y) {
      return dart.notNull(x) + dart.notNull(y);
    }
  });
  dart.setSignature(apply_test.Callable, {
    methods: () => ({call: dart.definiteFunctionType(core.int, [core.int, core.int])})
  });
  apply_test.confuse = function(x) {
    return x;
  };
  dart.fn(apply_test.confuse, dynamicTodynamic());
  apply_test.main = function() {
    function testMap(res, func, map) {
      map = symbol_map_helper.symbolMapToStringMap(MapOfString$dynamic()._check(map));
      expect$.Expect.equals(res, core.Function.apply(core.Function._check(func), null, MapOfSymbol$dynamic()._check(map)));
      expect$.Expect.equals(res, core.Function.apply(core.Function._check(func), [], MapOfSymbol$dynamic()._check(map)));
    }
    dart.fn(testMap, dynamicAnddynamicAnddynamicTodynamic());
    function testList(res, func, list) {
      expect$.Expect.equals(res, core.Function.apply(core.Function._check(func), core.List._check(list)));
      expect$.Expect.equals(res, core.Function.apply(core.Function._check(func), core.List._check(list), null));
      expect$.Expect.equals(res, core.Function.apply(core.Function._check(func), core.List._check(list), MapOfSymbol$dynamic().new()));
    }
    dart.fn(testList, dynamicAnddynamicAnddynamicTodynamic());
    function test(res, func, list, map) {
      map = symbol_map_helper.symbolMapToStringMap(MapOfString$dynamic()._check(map));
      expect$.Expect.equals(res, core.Function.apply(core.Function._check(func), core.List._check(list), MapOfSymbol$dynamic()._check(map)));
    }
    dart.fn(test, dynamicAnddynamicAnddynamic__Todynamic());
    testList(42, apply_test.test0, null);
    testList(42, apply_test.test0, []);
    testMap(42, apply_test.test0a, dart.map({a: 5}));
    testList(42, apply_test.test1, JSArrayOfint().of([41]));
    test(42, apply_test.test1a, JSArrayOfint().of([20]), dart.map({a: 22}));
    testList(42, apply_test.test2, JSArrayOfint().of([20, 22]));
    test(42, apply_test.test2a, JSArrayOfint().of([10, 15]), dart.map({a: 17}));
    let cfoo = dart.bind(new apply_test.C(), 'foo');
    testList(42, cfoo, JSArrayOfint().of([32]));
    let app = apply_test.confuse(core.Function.apply);
    expect$.Expect.equals(42, dart.dcall(app, apply_test.test2, JSArrayOfint().of([22, 20])));
    expect$.Expect.equals(42, core.Function.apply(core.Function.apply, JSArrayOfObject().of([apply_test.test2, JSArrayOfint().of([17, 25])])));
    testList(42, new apply_test.Callable(), JSArrayOfint().of([13, 29]));
  };
  dart.fn(apply_test.main, VoidTodynamic());
  symbol_map_helper.symbolMapToStringMap = function(map) {
    if (map == null) return null;
    let result = MapOfSymbol$dynamic().new();
    map[dartx.forEach](dart.fn((name, value) => {
      result[dartx.set](core.Symbol.new(name), value);
    }, StringAnddynamicTovoid()));
    return result;
  };
  dart.fn(symbol_map_helper.symbolMapToStringMap, MapOfString$dynamicToMapOfSymbol$dynamic());
  // Exports:
  exports.apply_test = apply_test;
  exports.symbol_map_helper = symbol_map_helper;
});
