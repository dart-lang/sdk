dart_library.library('language/super_in_async4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_in_async4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_in_async4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_in_async4_test.A = class A extends core.Object {
    foo(T) {
      return opts => {
        return dart.async(function*(opts) {
          let x = opts && 'x' in opts ? opts.x : null;
          return x;
        }, T, opts);
      };
    }
  };
  dart.setSignature(super_in_async4_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(T => [async.Future$(T), [], {x: T}])})
  });
  const super$foo = Symbol("super$foo");
  super_in_async4_test.B = class B extends super_in_async4_test.A {
    bar() {
      return dart.async((function*() {
        let x = (yield this[super$foo](core.int, {x: 41}));
        return dart.notNull(x) + 1;
      }).bind(this), core.int);
    }
    [super$foo](a, a$) {
      return super.foo(a)(a$);
    }
  };
  dart.setSignature(super_in_async4_test.B, {
    methods: () => ({bar: dart.definiteFunctionType(async.Future$(core.int), [])})
  });
  super_in_async4_test.main = function() {
    return dart.async(function*() {
      expect$.Expect.equals(42, yield new super_in_async4_test.B().bar());
    }, dart.dynamic);
  };
  dart.fn(super_in_async4_test.main, VoidTodynamic());
  // Exports:
  exports.super_in_async4_test = super_in_async4_test;
});
