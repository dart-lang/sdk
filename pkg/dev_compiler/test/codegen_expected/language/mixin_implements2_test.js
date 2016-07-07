dart_library.library('language/mixin_implements2_test', null, /* Imports */[
  'dart_sdk'
], function load__mixin_implements2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_implements2_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  mixin_implements2_test.A = class A extends core.Object {};
  mixin_implements2_test.S = class S extends core.Object {};
  mixin_implements2_test.M = class M extends core.Object {};
  mixin_implements2_test.C = class C extends dart.mixin(mixin_implements2_test.S, mixin_implements2_test.M) {
    new() {
      super.new();
    }
  };
  mixin_implements2_test.main = function() {
    new mixin_implements2_test.C();
  };
  dart.fn(mixin_implements2_test.main, VoidTovoid());
  // Exports:
  exports.mixin_implements2_test = mixin_implements2_test;
});
