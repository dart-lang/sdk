dart_library.library('corelib/double_round_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_round_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_round_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_round_test.main = function() {
    expect$.Expect.equals(0, 0.0[dartx.round]());
    expect$.Expect.equals(0, core.double.MIN_POSITIVE[dartx.round]());
    expect$.Expect.equals(0, (2.0 * dart.notNull(core.double.MIN_POSITIVE))[dartx.round]());
    expect$.Expect.equals(0, 1.18e-38[dartx.round]());
    expect$.Expect.equals(0, (1.18e-38 * 2)[dartx.round]());
    expect$.Expect.equals(1, 0.5[dartx.round]());
    expect$.Expect.equals(1, 0.9999999999999999[dartx.round]());
    expect$.Expect.equals(1, 1.0[dartx.round]());
    expect$.Expect.equals(1, 1.000000000000001[dartx.round]());
    expect$.Expect.equals(179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368, core.double.MAX_FINITE[dartx.round]());
    expect$.Expect.equals(0, (-dart.notNull(core.double.MIN_POSITIVE))[dartx.round]());
    expect$.Expect.equals(0, (2.0 * -dart.notNull(core.double.MIN_POSITIVE))[dartx.round]());
    expect$.Expect.equals(0, (-1.18e-38)[dartx.round]());
    expect$.Expect.equals(0, (-1.18e-38 * 2)[dartx.round]());
    expect$.Expect.equals(-1, (-0.5)[dartx.round]());
    expect$.Expect.equals(-1, (-0.9999999999999999)[dartx.round]());
    expect$.Expect.equals(-1, (-1.0)[dartx.round]());
    expect$.Expect.equals(-1, (-1.000000000000001)[dartx.round]());
    expect$.Expect.equals(-179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368, (-dart.notNull(core.double.MAX_FINITE))[dartx.round]());
    expect$.Expect.isTrue(typeof 0.0[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof core.double.MIN_POSITIVE[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (2.0 * dart.notNull(core.double.MIN_POSITIVE))[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof 1.18e-38[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (1.18e-38 * 2)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof 0.5[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof 0.9999999999999999[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof 1.0[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof 1.000000000000001[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof core.double.MAX_FINITE[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-dart.notNull(core.double.MIN_POSITIVE))[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (2.0 * -dart.notNull(core.double.MIN_POSITIVE))[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-1.18e-38)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-1.18e-38 * 2)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-0.5)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-0.9999999999999999)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-1.0)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-1.000000000000001)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-dart.notNull(core.double.MAX_FINITE))[dartx.round]() == 'number');
  };
  dart.fn(double_round_test.main, VoidTodynamic());
  // Exports:
  exports.double_round_test = double_round_test;
});
