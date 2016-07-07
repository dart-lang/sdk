dart_library.library('language/field_super_access2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__field_super_access2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const field_super_access2_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  field_super_access2_test.A = class A extends core.Object {
    new() {
      this.y = 42;
    }
  };
  field_super_access2_test.B = class B extends field_super_access2_test.A {
    new() {
      super.new();
    }
    get x() {
      return this.y;
    }
    set x(val) {}
  };
  field_super_access2_test.main = function() {
    let b = new field_super_access2_test.B();
    expect$.Expect.equals(42, b.x);
  };
  dart.fn(field_super_access2_test.main, VoidTovoid());
  // Exports:
  exports.field_super_access2_test = field_super_access2_test;
});
