dart_library.library('lib/math/double_pow_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_pow_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_pow_test = Object.create(null);
  let JSArrayOfdouble = () => (JSArrayOfdouble = dart.constFn(_interceptors.JSArray$(core.double)))();
  let doubleAnddoubleTovoid = () => (doubleAnddoubleTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.double, core.double])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_pow_test.checkVeryClose = function(a, b) {
    if (a == 0.0) {
      let minimalDouble = 5e-324;
      expect$.Expect.equals(true, dart.notNull(b[dartx.abs]()) <= minimalDouble);
      return;
    }
    if (b == 0.0) {
      expect$.Expect.equals(a, b);
    }
    let shiftRightBy52 = 2.220446049250313e-16;
    let shiftedA = (dart.notNull(a) * shiftRightBy52)[dartx.abs]();
    let limitLow = dart.notNull(a) - dart.notNull(shiftedA);
    let limitHigh = dart.notNull(a) + dart.notNull(shiftedA);
    expect$.Expect.equals(false, a == limitLow);
    expect$.Expect.equals(false, a == limitHigh);
    expect$.Expect.equals(true, limitLow <= dart.notNull(b));
    expect$.Expect.equals(true, dart.notNull(b) <= limitHigh);
  };
  dart.fn(double_pow_test.checkVeryClose, doubleAnddoubleTovoid());
  double_pow_test.NaN = core.double.NAN;
  double_pow_test.Infinity = core.double.INFINITY;
  dart.defineLazy(double_pow_test, {
    get samples() {
      return JSArrayOfdouble().of([double_pow_test.NaN, -double_pow_test.Infinity, -3.0, -2.0, -1.5, -1.0, -0.5, -0.0, 0.5, 1.0, 1.5, 2.0, 3.0, double_pow_test.Infinity]);
    },
    set samples(_) {}
  });
  double_pow_test.test = function() {
    for (let d of double_pow_test.samples) {
      expect$.Expect.identical(1.0, math.pow(d, 0.0), dart.str`${d}`);
      expect$.Expect.identical(1.0, math.pow(d, -0.0), dart.str`${d}`);
    }
    for (let d of double_pow_test.samples) {
      expect$.Expect.identical(1.0, math.pow(1.0, d), dart.str`${d}`);
    }
    for (let d of double_pow_test.samples) {
      if (d != 0.0) expect$.Expect.isTrue(math.pow(double_pow_test.NaN, d)[dartx.isNaN], dart.str`${d}`);
      if (d != 1.0) expect$.Expect.isTrue(math.pow(d, double_pow_test.NaN)[dartx.isNaN], dart.str`${d}`);
    }
    for (let d of double_pow_test.samples) {
      if (dart.notNull(d) < 0 && !dart.test(d[dartx.isInfinite])) {
        expect$.Expect.isTrue(math.pow(d, 0.5)[dartx.isNaN], dart.str`${d}`);
        expect$.Expect.isTrue(math.pow(d, -0.5)[dartx.isNaN], dart.str`${d}`);
        expect$.Expect.isTrue(math.pow(d, 1.5)[dartx.isNaN], dart.str`${d}`);
        expect$.Expect.isTrue(math.pow(d, -1.5)[dartx.isNaN], dart.str`${d}`);
      }
    }
    for (let d of double_pow_test.samples) {
      if (dart.notNull(d) < 0) {
        expect$.Expect.identical(0.0, math.pow(double_pow_test.Infinity, d), dart.str`${d}`);
      }
      if (dart.notNull(d) > 0) {
        expect$.Expect.identical(double_pow_test.Infinity, math.pow(double_pow_test.Infinity, d), dart.str`${d}`);
      }
    }
    for (let d of double_pow_test.samples) {
      if (dart.notNull(d) < 0) {
        expect$.Expect.identical(double_pow_test.Infinity, math.pow(0.0, d), dart.str`${d}`);
      }
      if (dart.notNull(d) > 0) {
        expect$.Expect.identical(0.0, math.pow(0.0, d), dart.str`${d}`);
      }
    }
    for (let d of double_pow_test.samples) {
      if (!dart.test(d[dartx.isInfinite]) && !dart.test(d[dartx.isNaN])) {
        let dint = d[dartx.toInt]();
        if (d == dint && dart.test(dint[dartx.isOdd])) {
          expect$.Expect.identical(-dart.notNull(math.pow(double_pow_test.Infinity, d)), math.pow(-double_pow_test.Infinity, d));
          expect$.Expect.identical(-dart.notNull(math.pow(0.0, d)), math.pow(-0.0, d));
          continue;
        }
      }
      expect$.Expect.identical(math.pow(double_pow_test.Infinity, d), math.pow(-double_pow_test.Infinity, d));
      expect$.Expect.identical(math.pow(0.0, d), math.pow(-0.0, d));
    }
    for (let d of double_pow_test.samples) {
      if (dart.notNull(d[dartx.abs]()) < 1) {
        expect$.Expect.identical(0.0, math.pow(d, double_pow_test.Infinity));
      } else if (dart.notNull(d[dartx.abs]()) > 1) {
        expect$.Expect.identical(double_pow_test.Infinity, math.pow(d, double_pow_test.Infinity));
      } else if (d == -1) {
        expect$.Expect.identical(1.0, math.pow(d, double_pow_test.Infinity));
      }
      expect$.Expect.identical(1 / dart.notNull(math.pow(d, double_pow_test.Infinity)), math.pow(d, -double_pow_test.Infinity));
    }
    double_pow_test.checkVeryClose(16.0, math.pow(4.0, 2.0));
    double_pow_test.checkVeryClose(math.SQRT2, math.pow(2.0, 0.5));
    double_pow_test.checkVeryClose(math.SQRT1_2, math.pow(0.5, 0.5));
    expect$.Expect.identical(5e-324, math.pow(2.0, -1074.0));
    expect$.Expect.identical(double_pow_test.Infinity, math.pow(10.0, 309.0));
    expect$.Expect.identical(0.0, math.pow(10.0, -325.0));
    expect$.Expect.identical(double_pow_test.Infinity, math.pow(-0.0, -9223372036854775809));
  };
  dart.fn(double_pow_test.test, VoidTodynamic());
  double_pow_test.main = function() {
    for (let i = 0; i < 10; i++)
      double_pow_test.test();
  };
  dart.fn(double_pow_test.main, VoidTodynamic());
  // Exports:
  exports.double_pow_test = double_pow_test;
});
