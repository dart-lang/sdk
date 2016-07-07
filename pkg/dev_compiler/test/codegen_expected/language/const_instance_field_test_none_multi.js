dart_library.library('language/const_instance_field_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__const_instance_field_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const const_instance_field_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const_instance_field_test_none_multi.C = class C extends core.Object {};
  const_instance_field_test_none_multi.main = function() {
    new const_instance_field_test_none_multi.C();
  };
  dart.fn(const_instance_field_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.const_instance_field_test_none_multi = const_instance_field_test_none_multi;
});
