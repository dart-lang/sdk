dart_library.library('language/bad_named_parameters_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__bad_named_parameters_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const bad_named_parameters_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  bad_named_parameters_test_none_multi.BadNamedParametersTest = class BadNamedParametersTest extends core.Object {
    f42(a, opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      let c = opts && 'c' in opts ? opts.c : 30;
      return 100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c);
    }
    f52(a, opts) {
      let b = opts && 'b' in opts ? opts.b : 20;
      let c = opts && 'c' in opts ? opts.c : null;
      let d = opts && 'd' in opts ? opts.d : 40;
      return 100 * (100 * (100 * dart.notNull(a) + dart.notNull(b)) + dart.notNull(c == null ? 0 : c)) + dart.notNull(d);
    }
    static testMain() {
      let np = new bad_named_parameters_test_none_multi.BadNamedParametersTest();
      let caught = null;
      try {
        caught = false;
      } catch (e) {
        if (core.NoSuchMethodError.is(e)) {
          caught = true;
        } else
          throw e;
      }

      try {
        caught = false;
      } catch (e) {
        if (core.NoSuchMethodError.is(e)) {
          caught = true;
        } else
          throw e;
      }

      try {
        caught = false;
      } catch (e) {
        if (core.NoSuchMethodError.is(e)) {
          caught = true;
        } else
          throw e;
      }

      try {
        caught = false;
      } catch (e) {
        if (core.NoSuchMethodError.is(e)) {
          caught = true;
        } else
          throw e;
      }

      try {
        caught = false;
      } catch (e) {
        if (core.NoSuchMethodError.is(e)) {
          caught = true;
        } else
          throw e;
      }

    }
  };
  dart.setSignature(bad_named_parameters_test_none_multi.BadNamedParametersTest, {
    methods: () => ({
      f42: dart.definiteFunctionType(core.int, [core.int], {b: core.int, c: core.int}),
      f52: dart.definiteFunctionType(core.int, [core.int], {b: core.int, c: core.int, d: core.int})
    }),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  bad_named_parameters_test_none_multi.main = function() {
    bad_named_parameters_test_none_multi.BadNamedParametersTest.testMain();
  };
  dart.fn(bad_named_parameters_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.bad_named_parameters_test_none_multi = bad_named_parameters_test_none_multi;
});
