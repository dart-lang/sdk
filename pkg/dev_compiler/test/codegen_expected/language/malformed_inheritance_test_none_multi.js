dart_library.library('language/malformed_inheritance_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__malformed_inheritance_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const malformed_inheritance_test_none_multi = Object.create(null);
  let A = () => (A = dart.constFn(malformed_inheritance_test_none_multi.A$()))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  malformed_inheritance_test_none_multi.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  malformed_inheritance_test_none_multi.A = A();
  malformed_inheritance_test_none_multi.C = class C extends core.Object {};
  malformed_inheritance_test_none_multi.main = function() {
    new malformed_inheritance_test_none_multi.C();
  };
  dart.fn(malformed_inheritance_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.malformed_inheritance_test_none_multi = malformed_inheritance_test_none_multi;
});
