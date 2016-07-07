dart_library.library('language/field_super_access_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__field_super_access_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const field_super_access_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  field_super_access_test.A = class A extends core.Object {
    new() {
      this.y = null;
    }
  };
  field_super_access_test.B = class B extends field_super_access_test.A {
    new() {
      super.new();
    }
    get x() {
      return this.y;
    }
    set x(val) {
      this.y = core.int._check(val);
    }
  };
  field_super_access_test.main = function() {
    let b = new field_super_access_test.B();
    b.x = 42;
    expect$.Expect.equals(42, b.x);
  };
  dart.fn(field_super_access_test.main, VoidTovoid());
  // Exports:
  exports.field_super_access_test = field_super_access_test;
});
