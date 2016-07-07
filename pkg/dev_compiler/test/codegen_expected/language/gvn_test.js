dart_library.library('language/gvn_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__gvn_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const gvn_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  gvn_test.A = class A extends core.Object {
    new() {
      this.x = 0;
    }
    foo(i) {
      let start = this.x;
      do {
        this.x = dart.notNull(this.x) + 1;
        i = dart.dsend(i, '+', 1);
      } while (!dart.equals(i, 10));
    }
  };
  dart.setSignature(gvn_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  gvn_test.main = function() {
    let a = new gvn_test.A();
    a.foo(0);
    expect$.Expect.equals(10, a.x);
  };
  dart.fn(gvn_test.main, VoidTodynamic());
  // Exports:
  exports.gvn_test = gvn_test;
});
