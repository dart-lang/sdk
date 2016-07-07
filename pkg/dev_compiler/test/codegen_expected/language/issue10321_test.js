dart_library.library('language/issue10321_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue10321_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue10321_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue10321_test.global = 54;
  issue10321_test.A = class A extends core.Object {
    new() {
      this.c = issue10321_test.global;
      this.a = 0;
      this.b = 42;
    }
    foo() {
      let start = dart.notNull(this.a) - 1;
      this.a = 54;
      if (this.b == 42) {
        this.b = 32;
      } else {
        this.b = 42;
      }
      expect$.Expect.equals(-1, start);
    }
    bar() {
      let start = dart.notNull(this.a) - dart.notNull(this.c) - 1;
      this.a = 42;
      if (this.b == 42) {
        this.b = 32;
      } else {
        this.b = 42;
      }
      expect$.Expect.equals(-55, start);
    }
  };
  dart.setSignature(issue10321_test.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  issue10321_test.main = function() {
    new issue10321_test.A().foo();
    new issue10321_test.A().bar();
  };
  dart.fn(issue10321_test.main, VoidTodynamic());
  // Exports:
  exports.issue10321_test = issue10321_test;
});
