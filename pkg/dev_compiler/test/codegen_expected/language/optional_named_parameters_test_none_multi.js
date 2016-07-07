dart_library.library('language/optional_named_parameters_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__optional_named_parameters_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const optional_named_parameters_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  optional_named_parameters_test_none_multi.OptionalNamedParametersTest = class OptionalNamedParametersTest extends core.Object {
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
    static F10(opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      return b;
    }
    f21(opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      return b;
    }
    static F21(a, opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      return 100 * dart.notNull(a) + dart.notNull(b);
    }
    f32(a, opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      return 100 * dart.notNull(a) + dart.notNull(b);
    }
    static F31(a, opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      let c = opts && 'c' in opts ? opts.c : 30;
      return 100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c);
    }
    f42(a, opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      let c = opts && 'c' in opts ? opts.c : 30;
      return 100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c);
    }
    static F41(a, opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      let c = opts && 'c' in opts ? opts.c : null;
      let d = opts && 'd' in opts ? opts.d : 40;
      return 100 * (100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c != null ? c : 0)) + dart.notNull(d);
    }
    f52(a, opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      let c = opts && 'c' in opts ? opts.c : null;
      let d = opts && 'd' in opts ? opts.d : 40;
      return 100 * (100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c != null ? c : 0)) + dart.notNull(d);
    }
    static test() {
      let np = new optional_named_parameters_test_none_multi.OptionalNamedParametersTest();
      expect$.Expect.equals(0, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F00());
      expect$.Expect.equals(0, np.f11());
      expect$.Expect.equals(10, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F11(10));
      expect$.Expect.equals(10, np.f22(10));
      expect$.Expect.equals(20, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F10());
      expect$.Expect.equals(20, np.f21());
      expect$.Expect.equals(20, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F10({b: 20}));
      expect$.Expect.equals(20, np.f21({b: 20}));
      expect$.Expect.equals(1020, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F21(10));
      expect$.Expect.equals(1020, np.f32(10));
      expect$.Expect.equals(1025, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F21(10, {b: 25}));
      expect$.Expect.equals(1025, np.f32(10, {b: 25}));
      expect$.Expect.equals(102030, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F31(10));
      expect$.Expect.equals(102030, np.f42(10));
      expect$.Expect.equals(102530, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F31(10, {b: 25}));
      expect$.Expect.equals(102530, np.f42(10, {b: 25}));
      expect$.Expect.equals(102035, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F31(10, {c: 35}));
      expect$.Expect.equals(102035, np.f42(10, {c: 35}));
      expect$.Expect.equals(102535, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F31(10, {b: 25, c: 35}));
      expect$.Expect.equals(102535, np.f42(10, {b: 25, c: 35}));
      expect$.Expect.equals(102535, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F31(10, {c: 35, b: 25}));
      expect$.Expect.equals(102535, np.f42(10, {c: 35, b: 25}));
      expect$.Expect.equals(10200040, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F41(10));
      expect$.Expect.equals(10200040, np.f52(10));
      expect$.Expect.equals(10203540, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F41(10, {c: 35}));
      expect$.Expect.equals(10203540, np.f52(10, {c: 35}));
      expect$.Expect.equals(10250045, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F41(10, {d: 45, b: 25}));
      expect$.Expect.equals(10250045, np.f52(10, {d: 45, b: 25}));
      expect$.Expect.equals(10253545, optional_named_parameters_test_none_multi.OptionalNamedParametersTest.F41(10, {d: 45, c: 35, b: 25}));
      expect$.Expect.equals(10253545, np.f52(10, {d: 45, c: 35, b: 25}));
    }
  };
  dart.setSignature(optional_named_parameters_test_none_multi.OptionalNamedParametersTest, {
    methods: () => ({
      f11: dart.definiteFunctionType(core.int, []),
      f22: dart.definiteFunctionType(core.int, [core.int]),
      f21: dart.definiteFunctionType(core.int, [], {b: core.int}),
      f32: dart.definiteFunctionType(core.int, [core.int], {b: core.int}),
      f42: dart.definiteFunctionType(core.int, [core.int], {b: core.int, c: core.int}),
      f52: dart.definiteFunctionType(core.int, [core.int], {b: core.int, c: core.int, d: core.int})
    }),
    statics: () => ({
      F00: dart.definiteFunctionType(core.int, []),
      F11: dart.definiteFunctionType(core.int, [core.int]),
      F10: dart.definiteFunctionType(core.int, [], {b: core.int}),
      F21: dart.definiteFunctionType(core.int, [core.int], {b: core.int}),
      F31: dart.definiteFunctionType(core.int, [core.int], {b: core.int, c: core.int}),
      F41: dart.definiteFunctionType(core.int, [core.int], {b: core.int, c: core.int, d: core.int}),
      test: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['F00', 'F11', 'F10', 'F21', 'F31', 'F41', 'test']
  });
  optional_named_parameters_test_none_multi.main = function() {
    optional_named_parameters_test_none_multi.OptionalNamedParametersTest.test();
  };
  dart.fn(optional_named_parameters_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.optional_named_parameters_test_none_multi = optional_named_parameters_test_none_multi;
});
