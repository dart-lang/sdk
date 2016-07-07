dart_library.library('language/private_clash_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__private_clash_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const private_clash_test = Object.create(null);
  const private_clash_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _b$_c$ = Symbol('_b$_c$');
  const _c$ = Symbol('_c$');
  private_clash_lib.B = class B extends core.Object {
    new() {
      this[_c$] = 10;
    }
    getValueA() {
      try {
      } catch (e) {
      }

      return this[_c$];
    }
  };
  dart.setSignature(private_clash_lib.B, {
    methods: () => ({getValueA: dart.definiteFunctionType(dart.dynamic, [])})
  });
  private_clash_test.A = class A extends private_clash_lib.B {
    new() {
      this[_b$_c$] = 100;
      super.new();
    }
    getValueB() {
      try {
      } catch (e) {
      }

      return this[_b$_c$];
    }
  };
  dart.setSignature(private_clash_test.A, {
    methods: () => ({getValueB: dart.definiteFunctionType(dart.dynamic, [])})
  });
  private_clash_test.main = function() {
    let a = new private_clash_test.A();
    expect$.Expect.equals(110, dart.dsend(a.getValueA(), '+', a.getValueB()));
  };
  dart.fn(private_clash_test.main, VoidTodynamic());
  // Exports:
  exports.private_clash_test = private_clash_test;
  exports.private_clash_lib = private_clash_lib;
});
