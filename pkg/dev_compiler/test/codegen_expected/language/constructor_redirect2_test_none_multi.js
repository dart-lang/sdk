dart_library.library('language/constructor_redirect2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__constructor_redirect2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constructor_redirect2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor_redirect2_test_none_multi.A = class A extends core.Object {
    new(x) {
      this.x = x;
    }
  };
  dart.setSignature(constructor_redirect2_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(constructor_redirect2_test_none_multi.A, [dart.dynamic])})
  });
  constructor_redirect2_test_none_multi.main = function() {
    new constructor_redirect2_test_none_multi.A(3);
  };
  dart.fn(constructor_redirect2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.constructor_redirect2_test_none_multi = constructor_redirect2_test_none_multi;
});
