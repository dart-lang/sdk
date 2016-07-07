dart_library.library('language/super_operator_index4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_operator_index4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_operator_index4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_operator_index4_test.A = class A extends core.Object {
    new() {
      this.indexField = core.List.new(2);
    }
    get(index) {
      return this.indexField[dartx.get](core.int._check(index));
    }
  };
  dart.setSignature(super_operator_index4_test.A, {
    methods: () => ({get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  super_operator_index4_test.B = class B extends super_operator_index4_test.A {
    new() {
      super.new();
    }
    set(index, value) {
      this.indexField[dartx.set](core.int._check(index), value);
      return value;
    }
  };
  dart.setSignature(super_operator_index4_test.B, {
    methods: () => ({set: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])})
  });
  super_operator_index4_test.C = class C extends super_operator_index4_test.B {
    test() {
      expect$.Expect.equals(42, super.set(0, 42));
      expect$.Expect.equals(42, super.get(0));
      expect$.Expect.equals(43, (() => {
        let i = 0;
        return super.set(i, dart.dsend(super.get(i), '+', 1));
      })());
      expect$.Expect.equals(43, super.get(0));
      expect$.Expect.equals(43, (() => {
        let i = 0, x = super.get(i);
        super.set(i, dart.dsend(x, '+', 1));
        return x;
      })());
      expect$.Expect.equals(44, super.get(0));
      expect$.Expect.equals(2, super.set(0, 2));
      expect$.Expect.equals(2, super.get(0));
      expect$.Expect.equals(3, (() => {
        let i = 0;
        return super.set(i, dart.dsend(super.get(i), '+', 1));
      })());
      expect$.Expect.equals(3, super.get(0));
      expect$.Expect.equals(3, (() => {
        let i = 0, x = super.get(i);
        super.set(i, dart.dsend(x, '+', 1));
        return x;
      })());
      expect$.Expect.equals(4, super.get(0));
    }
  };
  dart.setSignature(super_operator_index4_test.C, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_operator_index4_test.main = function() {
    new super_operator_index4_test.C().test();
  };
  dart.fn(super_operator_index4_test.main, VoidTodynamic());
  // Exports:
  exports.super_operator_index4_test = super_operator_index4_test;
});
