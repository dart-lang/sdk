dart_library.library('corelib/compare_to2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compare_to2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compare_to2_test = Object.create(null);
  let JSArrayOfnum = () => (JSArrayOfnum = dart.constFn(_interceptors.JSArray$(core.num)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compare_to2_test.negate = function(x) {
    return dart.dsend(x, 'unary-');
  };
  dart.fn(compare_to2_test.negate, dynamicTodynamic());
  compare_to2_test.main = function() {
    let minNonZero = 5e-324;
    let maxDenormal = 2.225073858507201e-308;
    let minNormal = 2.2250738585072014e-308;
    let maxFraction = 0.9999999999999999;
    let minAbove1 = 1.0000000000000002;
    let maxNonInt = 4503599627370495.5;
    let maxNonIntFloorAsInt = maxNonInt[dartx.floor]();
    let maxNonIntFloorAsDouble = maxNonIntFloorAsInt[dartx.toDouble]();
    let maxExactIntAsDouble = 9007199254740992.0;
    let maxExactIntAsInt = 9007199254740992;
    let two53 = (1)[dartx['<<']](53);
    let two53p1 = two53 + 1;
    let maxFiniteAsDouble = 1.7976931348623157e+308;
    let maxFiniteAsInt = maxFiniteAsDouble[dartx.truncate]();
    let huge = (1)[dartx['<<']](2000);
    let hugeP1 = huge + 1;
    let inf = core.double.INFINITY;
    let nan = core.double.NAN;
    let mnan = compare_to2_test.negate(nan);
    let matrix = JSArrayOfObject().of([-dart.notNull(inf), -hugeP1, -huge, JSArrayOfnum().of([-maxFiniteAsDouble, -dart.notNull(maxFiniteAsInt)]), -two53p1, JSArrayOfnum().of([-two53, -maxExactIntAsInt, -maxExactIntAsDouble]), -maxNonInt, JSArrayOfnum().of([-dart.notNull(maxNonIntFloorAsDouble), -dart.notNull(maxNonIntFloorAsInt)]), JSArrayOfnum().of([-499.0, -499]), -minAbove1, JSArrayOfnum().of([-1.0, -1]), -maxFraction, -minNormal, -maxDenormal, -minNonZero, -0.0, JSArrayOfint().of([0, 0, 0]), minNonZero, maxDenormal, minNormal, maxFraction, JSArrayOfnum().of([1.0, 1]), minAbove1, JSArrayOfnum().of([499.0, 499]), JSArrayOfnum().of([maxNonIntFloorAsDouble, maxNonIntFloorAsInt]), maxNonInt, JSArrayOfnum().of([two53, maxExactIntAsInt, maxExactIntAsDouble]), two53p1, JSArrayOfnum().of([maxFiniteAsDouble, maxFiniteAsInt]), huge, hugeP1, inf, [nan, mnan]]);
    function check(left, right, expectedResult) {
      if (core.List.is(left)) {
        for (let x of left)
          check(x, right, expectedResult);
        return;
      }
      if (core.List.is(right)) {
        for (let x of right)
          check(left, x, expectedResult);
        return;
      }
      let actual = core.int._check(dart.dsend(left, 'compareTo', right));
      expect$.Expect.equals(expectedResult, actual, dart.str`(${left}).compareTo(${right}) failed ` + dart.str`(should have been ${expectedResult}, was ${actual}`);
    }
    dart.fn(check, dynamicAnddynamicAnddynamicTodynamic());
    for (let i = 0; i < dart.notNull(matrix[dartx.length]); i++) {
      for (let j = 0; j < dart.notNull(matrix[dartx.length]); j++) {
        let left = matrix[dartx.get](i);
        let right = matrix[dartx.get](j);
        if (core.List.is(left)) {
          check(left, left, 0);
        }
        check(left, right, i == j ? 0 : i < j ? -1 : 1);
      }
    }
  };
  dart.fn(compare_to2_test.main, VoidTodynamic());
  // Exports:
  exports.compare_to2_test = compare_to2_test;
});
