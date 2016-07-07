dart_library.library('language/double_comparison_test', null, /* Imports */[
  'dart_sdk'
], function load__double_comparison_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const double_comparison_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_comparison_test.loop = function() {
    for (let d = 0.0; d < 1100.0; d++) {
    }
    for (let d = 0.0; d <= 1100.0; d++) {
    }
    for (let d = 1000.0; d > 0.0; d--) {
    }
    for (let d = 1000.0; d >= 0.0; d--) {
    }
  };
  dart.fn(double_comparison_test.loop, VoidTodynamic());
  double_comparison_test.main = function() {
    double_comparison_test.loop();
    double_comparison_test.loop();
  };
  dart.fn(double_comparison_test.main, VoidTodynamic());
  // Exports:
  exports.double_comparison_test = double_comparison_test;
});
