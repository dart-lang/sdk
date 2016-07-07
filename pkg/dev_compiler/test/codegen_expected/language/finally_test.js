dart_library.library('language/finally_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__finally_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const finally_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  finally_test.A = class A extends core.Object {
    new() {
      this.i = 42;
    }
    foo() {
      let executedFinally = false;
      if (this.i == 42) {
        try {
          this.i = 12;
        } finally {
          expect$.Expect.equals(12, this.i);
          executedFinally = true;
        }
      }
      expect$.Expect.isTrue(executedFinally);
    }
  };
  dart.setSignature(finally_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(finally_test.A, [])}),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  finally_test.main = function() {
    new finally_test.A().foo();
  };
  dart.fn(finally_test.main, VoidTodynamic());
  // Exports:
  exports.finally_test = finally_test;
});
