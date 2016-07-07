dart_library.library('language/super_operator_index2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_operator_index2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_operator_index2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_operator_index2_test.A = class A extends core.Object {
    new() {
      this.map = core.Map.new();
    }
    set(a, b) {
      this.map[dartx.set](a, b);
      return b;
    }
    get(a) {
      return this.map[dartx.get](a);
    }
  };
  dart.setSignature(super_operator_index2_test.A, {
    methods: () => ({
      set: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic]),
      get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  super_operator_index2_test.B = class B extends super_operator_index2_test.A {
    new() {
      super.new();
    }
    foo() {
      super.set(4, 42);
      expect$.Expect.equals(42, super.get(4));
      let i = 4;
      super.set(i, dart.dsend(super.get(i), '+', 5));
      expect$.Expect.equals(47, super.get(4));
    }
  };
  dart.setSignature(super_operator_index2_test.B, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_operator_index2_test.main = function() {
    new super_operator_index2_test.B().foo();
  };
  dart.fn(super_operator_index2_test.main, VoidTodynamic());
  // Exports:
  exports.super_operator_index2_test = super_operator_index2_test;
});
