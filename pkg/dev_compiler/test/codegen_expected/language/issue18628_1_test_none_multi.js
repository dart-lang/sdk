dart_library.library('language/issue18628_1_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__issue18628_1_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue18628_1_test_none_multi = Object.create(null);
  let C = () => (C = dart.constFn(issue18628_1_test_none_multi.C$()))();
  let COfType = () => (COfType = dart.constFn(issue18628_1_test_none_multi.C$(core.Type)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue18628_1_test_none_multi.C$ = dart.generic(T => {
    class C extends core.Object {}
    dart.addTypeTests(C);
    return C;
  });
  issue18628_1_test_none_multi.C = C();
  issue18628_1_test_none_multi.main = function() {
    let c = new (COfType())();
  };
  dart.fn(issue18628_1_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.issue18628_1_test_none_multi = issue18628_1_test_none_multi;
});
