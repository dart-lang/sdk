dart_library.library('language/super_in_finally_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_in_finally_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_in_finally_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_in_finally_test.A = class A extends core.Object {
    foo(T) {
      return opts => {
        let x = opts && 'x' in opts ? opts.x : null;
        return x;
      };
    }
  };
  dart.setSignature(super_in_finally_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(T => [dart.dynamic, [], {x: T}])})
  });
  const super$foo = Symbol("super$foo");
  super_in_finally_test.B = class B extends super_in_finally_test.A {
    bar() {
      try {
        dart.throw('bar');
        return 1;
      } finally {
        let x = this[super$foo](core.int, {x: 41});
        return core.int._check(dart.dsend(x, '+', 1));
      }
    }
    [super$foo](a, a$) {
      return super.foo(a)(a$);
    }
  };
  dart.setSignature(super_in_finally_test.B, {
    methods: () => ({bar: dart.definiteFunctionType(core.int, [])})
  });
  super_in_finally_test.main = function() {
    expect$.Expect.equals(42, new super_in_finally_test.B().bar());
  };
  dart.fn(super_in_finally_test.main, VoidTodynamic());
  // Exports:
  exports.super_in_finally_test = super_in_finally_test;
});
