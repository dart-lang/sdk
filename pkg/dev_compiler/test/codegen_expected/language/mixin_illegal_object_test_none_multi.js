dart_library.library('language/mixin_illegal_object_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__mixin_illegal_object_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_illegal_object_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_illegal_object_test_none_multi.S = class S extends core.Object {};
  mixin_illegal_object_test_none_multi.C0 = class C0 extends mixin_illegal_object_test_none_multi.S {};
  mixin_illegal_object_test_none_multi.main = function() {
    new mixin_illegal_object_test_none_multi.C0();
  };
  dart.fn(mixin_illegal_object_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.mixin_illegal_object_test_none_multi = mixin_illegal_object_test_none_multi;
});
