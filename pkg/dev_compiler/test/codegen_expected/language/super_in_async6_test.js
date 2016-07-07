dart_library.library('language/super_in_async6_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_in_async6_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_in_async6_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_in_async6_test.A = class A extends core.Object {
    foo(x, y, z) {
      return dart.async(function*(x, y, z) {
        return dart.notNull(x) + dart.notNull(y) + dart.notNull(z);
      }, core.int, x, y, z);
    }
  };
  dart.setSignature(super_in_async6_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(async.Future$(core.int), [core.int, core.int, core.int])})
  });
  const super$foo = Symbol("super$foo");
  super_in_async6_test.B = class B extends super_in_async6_test.A {
    foo(x, y, z) {
      return dart.async((function*(x, y, z) {
        let w = (yield this[super$foo](x, y, z));
        return dart.notNull(w) + 1;
      }).bind(this), core.int, x, y, z);
    }
    [super$foo](a, a$, a$0) {
      return super.foo(a, a$, a$0);
    }
  };
  super_in_async6_test.main = function() {
    return dart.async(function*() {
      expect$.Expect.equals(7, yield new super_in_async6_test.B().foo(1, 2, 3));
    }, dart.dynamic);
  };
  dart.fn(super_in_async6_test.main, VoidTodynamic());
  // Exports:
  exports.super_in_async6_test = super_in_async6_test;
});
