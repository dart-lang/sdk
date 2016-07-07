dart_library.library('language/gvn_field_access_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__gvn_field_access_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const gvn_field_access_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  gvn_field_access_test.A = class A extends core.Object {
    new() {
      this.y = 0;
    }
    foo(x) {
      let t = this.y;
      if (dart.notNull(t) < dart.notNull(core.num._check(x))) {
        for (let i = this.y; dart.notNull(i) < dart.notNull(core.num._check(x)); i = dart.notNull(i) + 1) {
          this.y = dart.notNull(this.y) + 1;
        }
      }
      return this.y;
    }
  };
  dart.setSignature(gvn_field_access_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  gvn_field_access_test.main = function() {
    expect$.Expect.equals(3, new gvn_field_access_test.A().foo(3));
  };
  dart.fn(gvn_field_access_test.main, VoidTovoid());
  // Exports:
  exports.gvn_field_access_test = gvn_field_access_test;
});
