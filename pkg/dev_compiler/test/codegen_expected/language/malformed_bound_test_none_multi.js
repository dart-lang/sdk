dart_library.library('language/malformed_bound_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__malformed_bound_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const malformed_bound_test_none_multi = Object.create(null);
  let C = () => (C = dart.constFn(malformed_bound_test_none_multi.C$()))();
  let COfint = () => (COfint = dart.constFn(malformed_bound_test_none_multi.C$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  malformed_bound_test_none_multi.C$ = dart.generic(T => {
    class C extends core.Object {}
    dart.addTypeTests(C);
    return C;
  });
  malformed_bound_test_none_multi.C = C();
  malformed_bound_test_none_multi.main = function() {
    new (COfint())();
  };
  dart.fn(malformed_bound_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.malformed_bound_test_none_multi = malformed_bound_test_none_multi;
});
