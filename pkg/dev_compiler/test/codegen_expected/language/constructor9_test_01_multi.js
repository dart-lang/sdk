dart_library.library('language/constructor9_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__constructor9_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constructor9_test_01_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor9_test_01_multi.Klass = class Klass extends core.Object {
    new(v) {
      this.field_ = v;
      this.uninitializedFinalField_ = null;
    }
  };
  dart.setSignature(constructor9_test_01_multi.Klass, {
    constructors: () => ({new: dart.definiteFunctionType(constructor9_test_01_multi.Klass, [dart.dynamic])})
  });
  constructor9_test_01_multi.main = function() {
    new constructor9_test_01_multi.Klass(5);
  };
  dart.fn(constructor9_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.constructor9_test_01_multi = constructor9_test_01_multi;
});
