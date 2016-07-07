dart_library.library('language/map_literal_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_literal_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_literal_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  map_literal_test.MapLiteralTest = class MapLiteralTest extends core.Object {
    new() {
    }
    static testMain() {
      let test = new map_literal_test.MapLiteralTest();
      test.testStaticInit();
      test.testConstInit();
    }
    testStaticInit() {
      let testClass = new map_literal_test.StaticInit();
      testClass.test();
    }
    testConstInit() {
      let testClass = new map_literal_test.ConstInit();
      testClass.test();
    }
    testLocalInit() {
      let map1 = dart.map({a: 1, b: 2});
      let map2 = dart.map({"1": 1, "2": 2});
      expect$.Expect.equals(1, map1[dartx.get]("a"));
      expect$.Expect.equals(2, map1[dartx.get]("b"));
      expect$.Expect.equals(1, map2[dartx.get]("1"));
      expect$.Expect.equals(2, map2[dartx.get]("2"));
    }
  };
  dart.setSignature(map_literal_test.MapLiteralTest, {
    constructors: () => ({new: dart.definiteFunctionType(map_literal_test.MapLiteralTest, [])}),
    methods: () => ({
      testStaticInit: dart.definiteFunctionType(dart.dynamic, []),
      testConstInit: dart.definiteFunctionType(dart.dynamic, []),
      testLocalInit: dart.definiteFunctionType(dart.dynamic, [])
    }),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  map_literal_test.StaticInit = class StaticInit extends core.Object {
    new() {
    }
    test() {
      expect$.Expect.equals(1, map_literal_test.StaticInit.map1[dartx.get]("a"));
      expect$.Expect.equals(2, map_literal_test.StaticInit.map1[dartx.get]("b"));
      expect$.Expect.equals(1, map_literal_test.StaticInit.map2[dartx.get]("1"));
      expect$.Expect.equals(2, map_literal_test.StaticInit.map2[dartx.get]("2"));
    }
  };
  dart.setSignature(map_literal_test.StaticInit, {
    constructors: () => ({new: dart.definiteFunctionType(map_literal_test.StaticInit, [])}),
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  map_literal_test.StaticInit.map1 = dart.const(dart.map({a: 1, b: 2}));
  map_literal_test.StaticInit.map2 = dart.const(dart.map({"1": 1, "2": 2}));
  map_literal_test.ConstInit = class ConstInit extends core.Object {
    new() {
      this.map1 = dart.map({a: 1, b: 2});
      this.map2 = dart.map({"1": 1, "2": 2});
    }
    test() {
      expect$.Expect.equals(1, dart.dindex(this.map1, "a"));
      expect$.Expect.equals(2, dart.dindex(this.map1, "b"));
      expect$.Expect.equals(1, dart.dindex(this.map2, "1"));
      expect$.Expect.equals(2, dart.dindex(this.map2, "2"));
    }
  };
  dart.setSignature(map_literal_test.ConstInit, {
    constructors: () => ({new: dart.definiteFunctionType(map_literal_test.ConstInit, [])}),
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  map_literal_test.main = function() {
    map_literal_test.MapLiteralTest.testMain();
  };
  dart.fn(map_literal_test.main, VoidTodynamic());
  // Exports:
  exports.map_literal_test = map_literal_test;
});
