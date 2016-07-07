dart_library.library('corelib/double_round_to_double_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_round_to_double_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_round_to_double_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_round_to_double_test.main = function() {
    expect$.Expect.equals(0.0, 0.0[dartx.roundToDouble]());
    expect$.Expect.equals(0.0, core.double.MIN_POSITIVE[dartx.roundToDouble]());
    expect$.Expect.equals(0.0, (2.0 * dart.notNull(core.double.MIN_POSITIVE))[dartx.roundToDouble]());
    expect$.Expect.equals(0.0, 1.18e-38[dartx.roundToDouble]());
    expect$.Expect.equals(0.0, (1.18e-38 * 2)[dartx.roundToDouble]());
    expect$.Expect.equals(1.0, 0.5[dartx.roundToDouble]());
    expect$.Expect.equals(1.0, 0.9999999999999999[dartx.roundToDouble]());
    expect$.Expect.equals(1.0, 1.0[dartx.roundToDouble]());
    expect$.Expect.equals(1.0, 1.000000000000001[dartx.roundToDouble]());
    expect$.Expect.equals(2.0, 1.5[dartx.roundToDouble]());
    expect$.Expect.equals(core.double.MAX_FINITE, core.double.MAX_FINITE[dartx.roundToDouble]());
    expect$.Expect.equals(0.0, (-dart.notNull(core.double.MIN_POSITIVE))[dartx.roundToDouble]());
    expect$.Expect.equals(0.0, (2.0 * -dart.notNull(core.double.MIN_POSITIVE))[dartx.roundToDouble]());
    expect$.Expect.equals(0.0, (-1.18e-38)[dartx.roundToDouble]());
    expect$.Expect.equals(0.0, (-1.18e-38 * 2)[dartx.roundToDouble]());
    expect$.Expect.equals(-1.0, (-0.5)[dartx.roundToDouble]());
    expect$.Expect.equals(-1.0, (-0.9999999999999999)[dartx.roundToDouble]());
    expect$.Expect.equals(-1.0, (-1.0)[dartx.roundToDouble]());
    expect$.Expect.equals(-1.0, (-1.000000000000001)[dartx.roundToDouble]());
    expect$.Expect.equals(-2.0, (-1.5)[dartx.roundToDouble]());
    expect$.Expect.equals(-dart.notNull(core.double.MAX_FINITE), (-dart.notNull(core.double.MAX_FINITE))[dartx.roundToDouble]());
    expect$.Expect.equals(core.double.INFINITY, core.double.INFINITY[dartx.roundToDouble]());
    expect$.Expect.equals(core.double.NEGATIVE_INFINITY, core.double.NEGATIVE_INFINITY[dartx.roundToDouble]());
    expect$.Expect.isTrue(core.double.NAN[dartx.roundToDouble]()[dartx.isNaN]);
    expect$.Expect.isTrue(typeof 0.0[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof core.double.MIN_POSITIVE[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (2.0 * dart.notNull(core.double.MIN_POSITIVE))[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof 1.18e-38[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (1.18e-38 * 2)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof 0.5[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof 0.9999999999999999[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof 1.0[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof 1.000000000000001[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof core.double.MAX_FINITE[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue((-dart.notNull(core.double.MIN_POSITIVE))[dartx.roundToDouble]()[dartx.isNegative]);
    expect$.Expect.isTrue((2.0 * -dart.notNull(core.double.MIN_POSITIVE))[dartx.roundToDouble]()[dartx.isNegative]);
    expect$.Expect.isTrue((-1.18e-38)[dartx.roundToDouble]()[dartx.isNegative]);
    expect$.Expect.isTrue((-1.18e-38 * 2)[dartx.roundToDouble]()[dartx.isNegative]);
    expect$.Expect.isTrue(typeof (-dart.notNull(core.double.MIN_POSITIVE))[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (2.0 * -dart.notNull(core.double.MIN_POSITIVE))[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-1.18e-38)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-1.18e-38 * 2)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-0.5)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-0.9999999999999999)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-1.0)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-1.000000000000001)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-dart.notNull(core.double.MAX_FINITE))[dartx.roundToDouble]() == 'number');
  };
  dart.fn(double_round_to_double_test.main, VoidTodynamic());
  // Exports:
  exports.double_round_to_double_test = double_round_to_double_test;
});
