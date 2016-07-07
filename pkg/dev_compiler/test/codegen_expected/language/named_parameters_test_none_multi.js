dart_library.library('language/named_parameters_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_parameters_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_parameters_test_none_multi = Object.create(null);
  let dynamicAnddynamic__Todynamic = () => (dynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic], {from: dart.dynamic})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameters_test_none_multi.NamedParametersTest = class NamedParametersTest extends core.Object {
    static F00() {
      return 0;
    }
    f11() {
      return 0;
    }
    static F11(a) {
      return a;
    }
    f22(a) {
      return a;
    }
    static F10(b) {
      if (b === void 0) b = 20;
      return b;
    }
    f21(b) {
      if (b === void 0) b = 20;
      return b;
    }
    static F21(a, b) {
      if (b === void 0) b = 20;
      return 100 * dart.notNull(a) + dart.notNull(b);
    }
    f32(a, b) {
      if (b === void 0) b = 20;
      return 100 * dart.notNull(a) + dart.notNull(b);
    }
    static F31(a, b, c) {
      if (b === void 0) b = 20;
      if (c === void 0) c = 30;
      return 100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c);
    }
    f42(a, b, c) {
      if (b === void 0) b = 20;
      if (c === void 0) c = 30;
      return 100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c);
    }
    static F41(a, b, c, d) {
      if (b === void 0) b = 20;
      if (c === void 0) c = null;
      if (d === void 0) d = 40;
      return 100 * (100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c == null ? 0 : c)) + dart.notNull(d);
    }
    f52(a, b, c, d) {
      if (b === void 0) b = 20;
      if (c === void 0) c = null;
      if (d === void 0) d = 40;
      return 100 * (100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c == null ? 0 : c)) + dart.notNull(d);
    }
    static testMain() {
      let np = new named_parameters_test_none_multi.NamedParametersTest();
      expect$.Expect.equals(0, named_parameters_test_none_multi.NamedParametersTest.F00());
      expect$.Expect.equals(0, np.f11());
      expect$.Expect.equals(10, named_parameters_test_none_multi.NamedParametersTest.F11(10));
      expect$.Expect.equals(10, np.f22(10));
      expect$.Expect.equals(20, named_parameters_test_none_multi.NamedParametersTest.F10());
      expect$.Expect.equals(20, np.f21());
      expect$.Expect.equals(20, named_parameters_test_none_multi.NamedParametersTest.F10(20));
      expect$.Expect.equals(20, np.f21(20));
      expect$.Expect.equals(1020, named_parameters_test_none_multi.NamedParametersTest.F21(10));
      expect$.Expect.equals(1020, np.f32(10));
      expect$.Expect.equals(1025, named_parameters_test_none_multi.NamedParametersTest.F21(10, 25));
      expect$.Expect.equals(1025, np.f32(10, 25));
      expect$.Expect.equals(102030, named_parameters_test_none_multi.NamedParametersTest.F31(10));
      expect$.Expect.equals(102030, np.f42(10));
      expect$.Expect.equals(102530, named_parameters_test_none_multi.NamedParametersTest.F31(10, 25));
      expect$.Expect.equals(102530, np.f42(10, 25));
      expect$.Expect.equals(102535, named_parameters_test_none_multi.NamedParametersTest.F31(10, 25, 35));
      expect$.Expect.equals(102535, np.f42(10, 25, 35));
      expect$.Expect.equals(10200040, named_parameters_test_none_multi.NamedParametersTest.F41(10));
      expect$.Expect.equals(10200040, np.f52(10));
    }
  };
  dart.setSignature(named_parameters_test_none_multi.NamedParametersTest, {
    methods: () => ({
      f11: dart.definiteFunctionType(core.int, []),
      f22: dart.definiteFunctionType(core.int, [core.int]),
      f21: dart.definiteFunctionType(core.int, [], [core.int]),
      f32: dart.definiteFunctionType(core.int, [core.int], [core.int]),
      f42: dart.definiteFunctionType(core.int, [core.int], [core.int, core.int]),
      f52: dart.definiteFunctionType(core.int, [core.int], [core.int, core.int, core.int])
    }),
    statics: () => ({
      F00: dart.definiteFunctionType(core.int, []),
      F11: dart.definiteFunctionType(core.int, [core.int]),
      F10: dart.definiteFunctionType(core.int, [], [core.int]),
      F21: dart.definiteFunctionType(core.int, [core.int], [core.int]),
      F31: dart.definiteFunctionType(core.int, [core.int], [core.int, core.int]),
      F41: dart.definiteFunctionType(core.int, [core.int], [core.int, core.int, core.int]),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['F00', 'F11', 'F10', 'F21', 'F31', 'F41', 'testMain']
  });
  named_parameters_test_none_multi.I = class I extends core.Object {
    static new() {
      return new named_parameters_test_none_multi.C();
    }
  };
  dart.setSignature(named_parameters_test_none_multi.I, {
    constructors: () => ({new: dart.definiteFunctionType(named_parameters_test_none_multi.I, [])})
  });
  named_parameters_test_none_multi.C = class C extends core.Object {
    mul(a, factor) {
      if (factor === void 0) factor = 10;
      return dart.notNull(a) * dart.notNull(factor);
    }
  };
  named_parameters_test_none_multi.C[dart.implements] = () => [named_parameters_test_none_multi.I];
  dart.setSignature(named_parameters_test_none_multi.C, {
    methods: () => ({mul: dart.definiteFunctionType(core.int, [core.int], [core.int])})
  });
  named_parameters_test_none_multi.hello = function(msg, to, opts) {
    let from = opts && 'from' in opts ? opts.from : null;
    return dart.str`${from} sent ${msg} to ${to}`;
  };
  dart.fn(named_parameters_test_none_multi.hello, dynamicAnddynamic__Todynamic());
  named_parameters_test_none_multi.message = function() {
    return named_parameters_test_none_multi.hello("gladiolas", "possums", {from: "Edna"});
  };
  dart.fn(named_parameters_test_none_multi.message, VoidTodynamic());
  named_parameters_test_none_multi.main = function() {
    named_parameters_test_none_multi.NamedParametersTest.testMain();
    let i = named_parameters_test_none_multi.I.new();
    expect$.Expect.equals(100, i.mul(10));
    expect$.Expect.equals(1000, i.mul(10, 100));
    let c = new named_parameters_test_none_multi.C();
    expect$.Expect.equals(100, c.mul(10));
    expect$.Expect.equals(1000, c.mul(10, 100));
    expect$.Expect.equals("Edna sent gladiolas to possums", named_parameters_test_none_multi.message());
  };
  dart.fn(named_parameters_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.named_parameters_test_none_multi = named_parameters_test_none_multi;
});
