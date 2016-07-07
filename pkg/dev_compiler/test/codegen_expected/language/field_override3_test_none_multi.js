dart_library.library('language/field_override3_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__field_override3_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const field_override3_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  field_override3_test_none_multi.A = class A extends core.Object {};
  field_override3_test_none_multi.B = class B extends field_override3_test_none_multi.A {};
  field_override3_test_none_multi.B.foo = 42;
  field_override3_test_none_multi.main = function() {
    expect$.Expect.equals(42, field_override3_test_none_multi.B.foo);
  };
  dart.fn(field_override3_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.field_override3_test_none_multi = field_override3_test_none_multi;
});
