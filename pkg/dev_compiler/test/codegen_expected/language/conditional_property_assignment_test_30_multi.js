dart_library.library('language/conditional_property_assignment_test_30_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__conditional_property_assignment_test_30_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const conditional_property_assignment_test_30_multi = Object.create(null);
  const conditional_access_helper = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToC = () => (VoidToC = dart.constFn(dart.definiteFunctionType(conditional_property_assignment_test_30_multi.C, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToC$ = () => (VoidToC$ = dart.constFn(dart.definiteFunctionType(conditional_access_helper.C, [])))();
  conditional_property_assignment_test_30_multi.bad = function() {
    expect$.Expect.fail('Should not be executed');
  };
  dart.fn(conditional_property_assignment_test_30_multi.bad, VoidTodynamic());
  conditional_property_assignment_test_30_multi.noMethod = function(e) {
    return core.NoSuchMethodError.is(e);
  };
  dart.fn(conditional_property_assignment_test_30_multi.noMethod, dynamicTodynamic());
  conditional_property_assignment_test_30_multi.B = class B extends core.Object {};
  conditional_property_assignment_test_30_multi.C = class C extends conditional_property_assignment_test_30_multi.B {
    new(v) {
      this.v = v;
    }
  };
  dart.setSignature(conditional_property_assignment_test_30_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(conditional_property_assignment_test_30_multi.C, [core.int])})
  });
  conditional_property_assignment_test_30_multi.C.staticInt = null;
  conditional_property_assignment_test_30_multi.D = class D extends core.Object {
    new(v) {
      this.v = v;
    }
  };
  dart.setSignature(conditional_property_assignment_test_30_multi.D, {
    constructors: () => ({new: dart.definiteFunctionType(conditional_property_assignment_test_30_multi.D, [conditional_property_assignment_test_30_multi.E])})
  });
  conditional_property_assignment_test_30_multi.D.staticE = null;
  conditional_property_assignment_test_30_multi.E = class E extends core.Object {
    ['+'](i) {
      return new conditional_property_assignment_test_30_multi.I();
    }
  };
  dart.setSignature(conditional_property_assignment_test_30_multi.E, {
    methods: () => ({'+': dart.definiteFunctionType(conditional_property_assignment_test_30_multi.G, [core.int])})
  });
  conditional_property_assignment_test_30_multi.F = class F extends core.Object {};
  conditional_property_assignment_test_30_multi.G = class G extends conditional_property_assignment_test_30_multi.E {};
  conditional_property_assignment_test_30_multi.G[dart.implements] = () => [conditional_property_assignment_test_30_multi.F];
  conditional_property_assignment_test_30_multi.H = class H extends core.Object {};
  conditional_property_assignment_test_30_multi.I = class I extends conditional_property_assignment_test_30_multi.G {};
  conditional_property_assignment_test_30_multi.I[dart.implements] = () => [conditional_property_assignment_test_30_multi.H];
  conditional_property_assignment_test_30_multi.nullC = function() {
    return null;
  };
  dart.fn(conditional_property_assignment_test_30_multi.nullC, VoidToC());
  conditional_property_assignment_test_30_multi.main = function() {
    let l = conditional_property_assignment_test_30_multi.nullC();
    l == null ? null : l.v = 1;
    {
      conditional_property_assignment_test_30_multi.D.staticE = new conditional_property_assignment_test_30_multi.E();
      let f = (() => {
        let o = conditional_property_assignment_test_30_multi.D;
        return o == null ? null : conditional_property_assignment_test_30_multi.D.staticE = dart.nullSafe(o, _ => _.staticE)['+'](1);
      })();
      expect$.Expect.identical(conditional_property_assignment_test_30_multi.D.staticE, f);
    }
  };
  dart.fn(conditional_property_assignment_test_30_multi.main, VoidTodynamic());
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
  exports.conditional_property_assignment_test_30_multi = conditional_property_assignment_test_30_multi;
  exports.conditional_access_helper = conditional_access_helper;
});
