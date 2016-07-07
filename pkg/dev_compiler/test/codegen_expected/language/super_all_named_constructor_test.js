dart_library.library('language/super_all_named_constructor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_all_named_constructor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_all_named_constructor_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_all_named_constructor_test.res = 0;
  super_all_named_constructor_test.A = class A extends core.Object {
    new(v) {
      if (v === void 0) v = 1;
      super_all_named_constructor_test.res = dart.notNull(super_all_named_constructor_test.res) + dart.notNull(core.int._check(v));
    }
  };
  dart.setSignature(super_all_named_constructor_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(super_all_named_constructor_test.A, [], [dart.dynamic])})
  });
  super_all_named_constructor_test.B = class B extends super_all_named_constructor_test.A {
    new(v) {
      if (v === void 0) v = 2;
      super.new();
      super_all_named_constructor_test.res = dart.notNull(super_all_named_constructor_test.res) + dart.notNull(core.int._check(v));
    }
  };
  dart.setSignature(super_all_named_constructor_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(super_all_named_constructor_test.B, [], [dart.dynamic])})
  });
  super_all_named_constructor_test.main = function() {
    new super_all_named_constructor_test.B();
    expect$.Expect.equals(3, super_all_named_constructor_test.res);
  };
  dart.fn(super_all_named_constructor_test.main, VoidTodynamic());
  // Exports:
  exports.super_all_named_constructor_test = super_all_named_constructor_test;
});
