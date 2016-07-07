dart_library.library('language/super_call_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_call_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_call_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_call_test.A = class A extends core.Object {
    new() {
      this.field = 0;
    }
    incrField() {
      this.field = dart.notNull(this.field) + 1;
    }
    timesX(v) {
      return dart.dsend(v, '*', 2);
    }
  };
  dart.setSignature(super_call_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(super_call_test.A, [])}),
    methods: () => ({
      incrField: dart.definiteFunctionType(dart.dynamic, []),
      timesX: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  super_call_test.B = class B extends super_call_test.A {
    incrField() {
      this.field = dart.notNull(this.field) + 1;
      super.incrField();
    }
    timesX(v) {
      return dart.dsend(super.timesX(v), '*', 3);
    }
    new() {
      super.new();
    }
  };
  dart.setSignature(super_call_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(super_call_test.B, [])})
  });
  super_call_test.SuperCallTest = class SuperCallTest extends core.Object {
    static testMain() {
      let b = new super_call_test.B();
      b.incrField();
      expect$.Expect.equals(2, b.field);
      expect$.Expect.equals(12, b.timesX(2));
    }
  };
  dart.setSignature(super_call_test.SuperCallTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  super_call_test.main = function() {
    super_call_test.SuperCallTest.testMain();
  };
  dart.fn(super_call_test.main, VoidTodynamic());
  // Exports:
  exports.super_call_test = super_call_test;
});
