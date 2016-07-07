dart_library.library('language/duplicate_implements_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__duplicate_implements_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const duplicate_implements_test_none_multi = Object.create(null);
  let K = () => (K = dart.constFn(duplicate_implements_test_none_multi.K$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  duplicate_implements_test_none_multi.I = class I extends core.Object {};
  duplicate_implements_test_none_multi.J = class J extends core.Object {};
  duplicate_implements_test_none_multi.K$ = dart.generic(T => {
    class K extends core.Object {}
    dart.addTypeTests(K);
    return K;
  });
  duplicate_implements_test_none_multi.K = K();
  duplicate_implements_test_none_multi.main = function() {
  };
  dart.fn(duplicate_implements_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.duplicate_implements_test_none_multi = duplicate_implements_test_none_multi;
});
