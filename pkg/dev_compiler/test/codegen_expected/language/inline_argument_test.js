dart_library.library('language/inline_argument_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inline_argument_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inline_argument_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inline_argument_test.A = class A extends core.Object {
    new() {
      this.field = 0;
    }
    foo(b) {
      expect$.Expect.equals(0, b);
      expect$.Expect.equals(0, b);
    }
    bar() {
      this.foo((() => {
        let x = this.field;
        this.field = dart.notNull(x) + 1;
        return x;
      })());
    }
  };
  dart.setSignature(inline_argument_test.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  inline_argument_test.main = function() {
    let a = new inline_argument_test.A();
    a.bar();
    expect$.Expect.equals(1, a.field);
  };
  dart.fn(inline_argument_test.main, VoidTodynamic());
  // Exports:
  exports.inline_argument_test = inline_argument_test;
});
