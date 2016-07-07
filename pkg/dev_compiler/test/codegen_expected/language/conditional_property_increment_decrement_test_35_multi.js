dart_library.library('language/conditional_property_increment_decrement_test_35_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__conditional_property_increment_decrement_test_35_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const conditional_property_increment_decrement_test_35_multi = Object.create(null);
  const conditional_access_helper = Object.create(null);
  let VoidToC = () => (VoidToC = dart.constFn(dart.definiteFunctionType(conditional_property_increment_decrement_test_35_multi.C, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToC$ = () => (VoidToC$ = dart.constFn(dart.definiteFunctionType(conditional_access_helper.C, [])))();
  conditional_property_increment_decrement_test_35_multi.C = class C extends core.Object {
    new(v) {
      this.v = v;
    }
  };
  dart.setSignature(conditional_property_increment_decrement_test_35_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(conditional_property_increment_decrement_test_35_multi.C, [core.int])})
  });
  conditional_property_increment_decrement_test_35_multi.C.staticInt = null;
  conditional_property_increment_decrement_test_35_multi.D = class D extends core.Object {
    new(v) {
      this.v = v;
    }
  };
  dart.setSignature(conditional_property_increment_decrement_test_35_multi.D, {
    constructors: () => ({new: dart.definiteFunctionType(conditional_property_increment_decrement_test_35_multi.D, [conditional_property_increment_decrement_test_35_multi.E])})
  });
  conditional_property_increment_decrement_test_35_multi.D.staticE = null;
  conditional_property_increment_decrement_test_35_multi.E = class E extends core.Object {
    ['+'](i) {
      return new conditional_property_increment_decrement_test_35_multi.I();
    }
    ['-'](i) {
      return new conditional_property_increment_decrement_test_35_multi.I();
    }
  };
  dart.setSignature(conditional_property_increment_decrement_test_35_multi.E, {
    methods: () => ({
      '+': dart.definiteFunctionType(conditional_property_increment_decrement_test_35_multi.G, [core.int]),
      '-': dart.definiteFunctionType(conditional_property_increment_decrement_test_35_multi.G, [core.int])
    })
  });
  conditional_property_increment_decrement_test_35_multi.F = class F extends core.Object {};
  conditional_property_increment_decrement_test_35_multi.G = class G extends conditional_property_increment_decrement_test_35_multi.E {};
  conditional_property_increment_decrement_test_35_multi.G[dart.implements] = () => [conditional_property_increment_decrement_test_35_multi.F];
  conditional_property_increment_decrement_test_35_multi.H = class H extends core.Object {};
  conditional_property_increment_decrement_test_35_multi.I = class I extends conditional_property_increment_decrement_test_35_multi.G {};
  conditional_property_increment_decrement_test_35_multi.I[dart.implements] = () => [conditional_property_increment_decrement_test_35_multi.H];
  conditional_property_increment_decrement_test_35_multi.nullC = function() {
    return null;
  };
  dart.fn(conditional_property_increment_decrement_test_35_multi.nullC, VoidToC());
  conditional_property_increment_decrement_test_35_multi.main = function() {
    let l = conditional_property_increment_decrement_test_35_multi.nullC();
    l == null ? null : l.v = 1;
    {
      conditional_property_increment_decrement_test_35_multi.C.staticInt = 1;
      expect$.Expect.equals(0, (() => {
        let o = conditional_property_increment_decrement_test_35_multi.C;
        return o == null ? null : conditional_property_increment_decrement_test_35_multi.C.staticInt = dart.notNull(dart.nullSafe(o, _ => _.staticInt)) - 1;
      })());
      expect$.Expect.equals(0, conditional_property_increment_decrement_test_35_multi.C.staticInt);
    }
  };
  dart.fn(conditional_property_increment_decrement_test_35_multi.main, VoidTodynamic());
  conditional_access_helper.topLevelVar = null;
  conditional_access_helper.topLevelFunction = function() {
  };
  dart.fn(conditional_access_helper.topLevelFunction, VoidTovoid());
  conditional_access_helper.C = class C extends core.Object {
    static staticF(callback) {
      return callback();
    }
    static staticG(callback) {
      return callback();
    }
  };
  dart.setSignature(conditional_access_helper.C, {
    statics: () => ({
      staticF: dart.definiteFunctionType(dart.dynamic, [dart.functionType(dart.dynamic, [])]),
      staticG: dart.definiteFunctionType(core.int, [dart.functionType(core.int, [])])
    }),
    names: ['staticF', 'staticG']
  });
  conditional_access_helper.C.staticInt = null;
  conditional_access_helper.nullC = function() {
    return null;
  };
  dart.fn(conditional_access_helper.nullC, VoidToC$());
  conditional_access_helper.D = class D extends core.Object {};
  conditional_access_helper.D.staticE = null;
  conditional_access_helper.E = class E extends core.Object {
    ['+'](i) {
      return new conditional_access_helper.I();
    }
    ['-'](i) {
      return new conditional_access_helper.I();
    }
  };
  dart.setSignature(conditional_access_helper.E, {
    methods: () => ({
      '+': dart.definiteFunctionType(conditional_access_helper.G, [core.int]),
      '-': dart.definiteFunctionType(conditional_access_helper.G, [core.int])
    })
  });
  conditional_access_helper.F = class F extends core.Object {};
  conditional_access_helper.G = class G extends conditional_access_helper.E {};
  conditional_access_helper.G[dart.implements] = () => [conditional_access_helper.F];
  conditional_access_helper.H = class H extends core.Object {};
  conditional_access_helper.I = class I extends conditional_access_helper.G {};
  conditional_access_helper.I[dart.implements] = () => [conditional_access_helper.H];
  // Exports:
  exports.conditional_property_increment_decrement_test_35_multi = conditional_property_increment_decrement_test_35_multi;
  exports.conditional_access_helper = conditional_access_helper;
});
