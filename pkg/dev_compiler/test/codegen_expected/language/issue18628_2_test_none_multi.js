dart_library.library('language/issue18628_2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__issue18628_2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue18628_2_test_none_multi = Object.create(null);
  let X = () => (X = dart.constFn(issue18628_2_test_none_multi.X$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue18628_2_test_none_multi.X$ = dart.generic(T => {
    class X extends core.Object {}
    dart.addTypeTests(X);
    return X;
  });
  issue18628_2_test_none_multi.X = X();
  issue18628_2_test_none_multi.main = function() {
  };
  dart.fn(issue18628_2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.issue18628_2_test_none_multi = issue18628_2_test_none_multi;
});
