dart_library.library('corelib/double_compare_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_compare_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_compare_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  double_compare_test.main = function() {
    expect$.Expect.equals(0, 0.0[dartx.compareTo](0.0));
    expect$.Expect.equals(0, 1.0[dartx.compareTo](1.0));
    expect$.Expect.equals(0, (-2.0)[dartx.compareTo](-2.0));
    expect$.Expect.equals(0, (1e-50)[dartx.compareTo](1e-50));
    expect$.Expect.equals(0, (-2e+50)[dartx.compareTo](-2e+50));
    expect$.Expect.equals(0, core.double.NAN[dartx.compareTo](core.double.NAN));
    expect$.Expect.equals(0, core.double.INFINITY[dartx.compareTo](core.double.INFINITY));
    expect$.Expect.equals(0, core.double.NEGATIVE_INFINITY[dartx.compareTo](core.double.NEGATIVE_INFINITY));
    expect$.Expect.equals(0, (-0.0)[dartx.compareTo](-0.0));
    expect$.Expect.isTrue(dart.notNull(0.0[dartx.compareTo](1.0)) < 0);
    expect$.Expect.isTrue(dart.notNull(1.0[dartx.compareTo](0.0)) > 0);
    expect$.Expect.isTrue(dart.notNull(0.0[dartx.compareTo](-1.0)) > 0);
    expect$.Expect.isTrue(dart.notNull((-1.0)[dartx.compareTo](0.0)) < 0);
    expect$.Expect.isTrue(dart.notNull(0.0[dartx.compareTo](123400000000000.0)) < 0);
    expect$.Expect.isTrue(dart.notNull(1.23e-110[dartx.compareTo](0.0)) > 0);
    expect$.Expect.isTrue(dart.notNull(0.0[dartx.compareTo](-123000000000000.0)) > 0);
    expect$.Expect.isTrue(dart.notNull((-100000000.0)[dartx.compareTo](0.0)) < 0);
    let maxDouble = 1.7976931348623157e+308;
    expect$.Expect.equals(0, maxDouble[dartx.compareTo](maxDouble));
    expect$.Expect.isTrue(dart.notNull(maxDouble[dartx.compareTo](core.double.INFINITY)) < 0);
    expect$.Expect.isTrue(dart.notNull(core.double.INFINITY[dartx.compareTo](maxDouble)) > 0);
    let negMaxDouble = -maxDouble;
    expect$.Expect.equals(0, negMaxDouble[dartx.compareTo](negMaxDouble));
    expect$.Expect.isTrue(dart.notNull(core.double.NEGATIVE_INFINITY[dartx.compareTo](negMaxDouble)) < 0);
    expect$.Expect.isTrue(dart.notNull(negMaxDouble[dartx.compareTo](core.double.NEGATIVE_INFINITY)) > 0);
    expect$.Expect.isTrue(dart.notNull((-0.0)[dartx.compareTo](0.0)) < 0);
    expect$.Expect.isTrue(dart.notNull(0.0[dartx.compareTo](-0.0)) > 0);
    expect$.Expect.isTrue(dart.notNull(core.double.NAN[dartx.compareTo](core.double.INFINITY)) > 0);
    expect$.Expect.isTrue(dart.notNull(core.double.NAN[dartx.compareTo](core.double.NEGATIVE_INFINITY)) > 0);
    expect$.Expect.isTrue(dart.notNull(core.double.INFINITY[dartx.compareTo](core.double.NAN)) < 0);
    expect$.Expect.isTrue(dart.notNull(core.double.NEGATIVE_INFINITY[dartx.compareTo](core.double.NAN)) < 0);
    expect$.Expect.isTrue(dart.notNull(maxDouble[dartx.compareTo](core.double.NAN)) < 0);
    expect$.Expect.isTrue(dart.notNull(negMaxDouble[dartx.compareTo](core.double.NAN)) < 0);
    expect$.Expect.isTrue(dart.notNull(core.double.NAN[dartx.compareTo](maxDouble)) > 0);
    expect$.Expect.isTrue(dart.notNull(core.double.NAN[dartx.compareTo](negMaxDouble)) > 0);
  };
  dart.fn(double_compare_test.main, VoidTovoid());
  // Exports:
  exports.double_compare_test = double_compare_test;
});
