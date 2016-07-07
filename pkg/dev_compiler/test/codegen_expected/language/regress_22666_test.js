dart_library.library('language/regress_22666_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_22666_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_22666_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_22666_test.A = class A extends dart.mixin(core.Object, collection.LinkedListEntry$(regress_22666_test.A)) {
    new() {
      super.new();
    }
  };
  regress_22666_test.main = function() {
    return new regress_22666_test.A();
  };
  dart.fn(regress_22666_test.main, VoidTodynamic());
  // Exports:
  exports.regress_22666_test = regress_22666_test;
});
