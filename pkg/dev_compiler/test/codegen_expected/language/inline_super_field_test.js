dart_library.library('language/inline_super_field_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inline_super_field_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inline_super_field_test = Object.create(null);
  const inline_super_field_lib = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  inline_super_field_test.S = class S extends core.Object {};
  inline_super_field_lib.M1 = class M1 extends core.Object {
    new() {
      this.bar = (inline_super_field_lib.i = dart.notNull(inline_super_field_lib.i) + 1);
    }
  };
  inline_super_field_test.C = class C extends dart.mixin(inline_super_field_test.S, inline_super_field_lib.M1) {
    new() {
      super.new();
    }
  };
  inline_super_field_test.main = function() {
    let c = new inline_super_field_test.C();
    expect$.Expect.equals(1, c.bar);
  };
  dart.fn(inline_super_field_test.main, VoidTovoid());
  inline_super_field_lib.i = 0;
  // Exports:
  exports.inline_super_field_test = inline_super_field_test;
  exports.inline_super_field_lib = inline_super_field_lib;
});
