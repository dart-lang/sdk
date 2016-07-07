dart_library.library('language/super_setter_interceptor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_setter_interceptor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_setter_interceptor_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_setter_interceptor_test.expected = null;
  super_setter_interceptor_test.A = class A extends core.Object {
    set length(a) {
      expect$.Expect.equals(super_setter_interceptor_test.expected, a);
    }
    get length() {
      return 41;
    }
  };
  super_setter_interceptor_test.B = class B extends super_setter_interceptor_test.A {
    test() {
      super_setter_interceptor_test.expected = 42;
      expect$.Expect.equals(42, super.length = 42);
      super_setter_interceptor_test.expected = 42;
      expect$.Expect.equals(42, (super.length = dart.dsend(super.length, '+', 1)));
      super_setter_interceptor_test.expected = 42;
      expect$.Expect.equals(42, (super.length = dart.dsend(super.length, '+', 1)));
      super_setter_interceptor_test.expected = 40;
      expect$.Expect.equals(40, (super.length = dart.dsend(super.length, '-', 1)));
      super_setter_interceptor_test.expected = 42;
      expect$.Expect.equals(41, (() => {
        let x = super.length;
        super.length = dart.dsend(x, '+', 1);
        return x;
      })());
      super_setter_interceptor_test.expected = 40;
      expect$.Expect.equals(41, (() => {
        let x = super.length;
        super.length = dart.dsend(x, '-', 1);
        return x;
      })());
      expect$.Expect.equals(41, super.length);
    }
  };
  dart.setSignature(super_setter_interceptor_test.B, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_setter_interceptor_test.main = function() {
    core.print([]);
    new super_setter_interceptor_test.B().test();
  };
  dart.fn(super_setter_interceptor_test.main, VoidTodynamic());
  // Exports:
  exports.super_setter_interceptor_test = super_setter_interceptor_test;
});
