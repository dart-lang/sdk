dart_library.library('language/constructor7_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor7_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor7_test = Object.create(null);
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor7_test.trace = "";
  constructor7_test.E = function(i) {
    constructor7_test.trace = dart.notNull(constructor7_test.trace) + dart.str`${i}-`;
    return i;
  };
  dart.fn(constructor7_test.E, intToint());
  constructor7_test.A = class A extends core.Object {
    new() {
      this.a = constructor7_test.E(1);
      this.b = constructor7_test.E(2);
      this.c = constructor7_test.E(3);
      this.f = constructor7_test.E(4);
      this.e = constructor7_test.E(5);
      this.d = constructor7_test.E(6);
      this.g = constructor7_test.E(7);
      this.h = constructor7_test.E(8);
      this.i = constructor7_test.E(9);
      this.j = constructor7_test.E(10);
      expect$.Expect.equals(1, this.a);
      expect$.Expect.equals(2, this.b);
      expect$.Expect.equals(3, this.c);
      expect$.Expect.equals(4, this.f);
      expect$.Expect.equals(5, this.e);
      expect$.Expect.equals(6, this.d);
      expect$.Expect.equals(7, this.g);
      expect$.Expect.equals(8, this.h);
      expect$.Expect.equals(9, this.i);
      expect$.Expect.equals(10, this.j);
    }
  };
  dart.setSignature(constructor7_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(constructor7_test.A, [])})
  });
  constructor7_test.main = function() {
    let x = new constructor7_test.A();
    expect$.Expect.equals('1-2-3-4-5-6-7-8-9-10-', constructor7_test.trace);
  };
  dart.fn(constructor7_test.main, VoidTodynamic());
  // Exports:
  exports.constructor7_test = constructor7_test;
});
