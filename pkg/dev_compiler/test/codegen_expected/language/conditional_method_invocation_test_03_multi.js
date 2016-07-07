dart_library.library('language/conditional_method_invocation_test_03_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__conditional_method_invocation_test_03_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const conditional_method_invocation_test_03_multi = Object.create(null);
  const conditional_access_helper = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.functionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToC = () => (VoidToC = dart.constFn(dart.definiteFunctionType(conditional_method_invocation_test_03_multi.C, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToC$ = () => (VoidToC$ = dart.constFn(dart.definiteFunctionType(conditional_access_helper.C, [])))();
  conditional_method_invocation_test_03_multi.bad = function() {
    expect$.Expect.fail('Should not be executed');
  };
  dart.fn(conditional_method_invocation_test_03_multi.bad, VoidTodynamic());
  conditional_method_invocation_test_03_multi.noMethod = function(e) {
    return core.NoSuchMethodError.is(e);
  };
  dart.fn(conditional_method_invocation_test_03_multi.noMethod, dynamicTodynamic());
  conditional_method_invocation_test_03_multi.B = class B extends core.Object {};
  conditional_method_invocation_test_03_multi.C = class C extends conditional_method_invocation_test_03_multi.B {
    f(callback) {
      return callback();
    }
    g(callback) {
      return callback();
    }
    static staticF(callback) {
      return callback();
    }
    static staticG(callback) {
      return callback();
    }
  };
  dart.setSignature(conditional_method_invocation_test_03_multi.C, {
    methods: () => ({
      f: dart.definiteFunctionType(dart.dynamic, [dart.functionType(dart.dynamic, [])]),
      g: dart.definiteFunctionType(core.int, [dart.functionType(core.int, [])])
    }),
    statics: () => ({
      staticF: dart.definiteFunctionType(dart.dynamic, [dart.functionType(dart.dynamic, [])]),
      staticG: dart.definiteFunctionType(core.int, [dart.functionType(core.int, [])])
    }),
    names: ['staticF', 'staticG']
  });
  conditional_method_invocation_test_03_multi.nullC = function() {
    return null;
  };
  dart.fn(conditional_method_invocation_test_03_multi.nullC, VoidToC());
  conditional_method_invocation_test_03_multi.main = function() {
    dart.nullSafe(conditional_method_invocation_test_03_multi.nullC(), _ => _.f(null));
    {
      let i = dart.nullSafe(conditional_method_invocation_test_03_multi.nullC(), _ => _.g(VoidToint()._check(conditional_method_invocation_test_03_multi.bad())));
      expect$.Expect.equals(null, i);
    }
  };
  dart.fn(conditional_method_invocation_test_03_multi.main, VoidTodynamic());
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
  exports.conditional_method_invocation_test_03_multi = conditional_method_invocation_test_03_multi;
  exports.conditional_access_helper = conditional_access_helper;
});
