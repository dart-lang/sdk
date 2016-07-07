dart_library.library('language/unresolved_default_constructor_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__unresolved_default_constructor_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unresolved_default_constructor_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  unresolved_default_constructor_test_none_multi.A = class A extends core.Object {
    named() {
    }
    static method() {}
  };
  dart.defineNamedConstructor(unresolved_default_constructor_test_none_multi.A, 'named');
  dart.setSignature(unresolved_default_constructor_test_none_multi.A, {
    constructors: () => ({named: dart.definiteFunctionType(unresolved_default_constructor_test_none_multi.A, [])}),
    statics: () => ({method: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['method']
  });
  unresolved_default_constructor_test_none_multi.main = function() {
    unresolved_default_constructor_test_none_multi.A.method();
  };
  dart.fn(unresolved_default_constructor_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.unresolved_default_constructor_test_none_multi = unresolved_default_constructor_test_none_multi;
});
