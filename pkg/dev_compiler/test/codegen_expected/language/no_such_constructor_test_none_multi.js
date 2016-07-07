dart_library.library('language/no_such_constructor_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__no_such_constructor_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const no_such_constructor_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  no_such_constructor_test_none_multi.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(no_such_constructor_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(no_such_constructor_test_none_multi.A, [])})
  });
  no_such_constructor_test_none_multi.main = function() {
  };
  dart.fn(no_such_constructor_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.no_such_constructor_test_none_multi = no_such_constructor_test_none_multi;
});
