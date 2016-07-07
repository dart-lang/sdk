dart_library.library('language/double_modulo_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_modulo_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_modulo_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  double_modulo_test.main = function() {
    let k = -0.33333;
    let firstResPos = core.double._check(double_modulo_test.doMod(k, 1.0));
    let firstResNeg = core.double._check(double_modulo_test.doMod(k, -1.0));
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals(firstResPos, double_modulo_test.doMod(k, 1.0));
      expect$.Expect.equals(firstResNeg, double_modulo_test.doMod(k, -1.0));
    }
  };
  dart.fn(double_modulo_test.main, VoidTodynamic());
  double_modulo_test.doMod = function(a, b) {
    return dart.dsend(a, '%', b);
  };
  dart.fn(double_modulo_test.doMod, dynamicAnddynamicTodynamic());
  // Exports:
  exports.double_modulo_test = double_modulo_test;
});
