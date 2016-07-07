dart_library.library('language/field3a_negative_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__field3a_negative_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const field3a_negative_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  field3a_negative_test.C = class C extends core.Object {
    new() {
      this.a = null;
    }
  };
  field3a_negative_test.main = function() {
    let val = new field3a_negative_test.C();
    expect$.Expect.equals(val.a, 0);
  };
  dart.fn(field3a_negative_test.main, VoidTodynamic());
  // Exports:
  exports.field3a_negative_test = field3a_negative_test;
});
