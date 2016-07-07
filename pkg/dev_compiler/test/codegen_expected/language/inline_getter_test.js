dart_library.library('language/inline_getter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inline_getter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inline_getter_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inline_getter_test.A = class A extends core.Object {
    new(f) {
      this.f = f;
    }
    foo() {
      return this.f;
    }
  };
  dart.setSignature(inline_getter_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(inline_getter_test.A, [core.int])}),
    methods: () => ({foo: dart.definiteFunctionType(core.int, [])})
  });
  inline_getter_test.B = class B extends inline_getter_test.A {
    new() {
      super.new(2);
    }
  };
  dart.setSignature(inline_getter_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(inline_getter_test.B, [])})
  });
  inline_getter_test.C = class C extends inline_getter_test.A {
    new() {
      super.new(10);
    }
  };
  dart.setSignature(inline_getter_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(inline_getter_test.C, [])})
  });
  inline_getter_test.InlineGetterTest = class InlineGetterTest extends core.Object {
    static testMain() {
      let a = new inline_getter_test.A(1);
      let b = new inline_getter_test.B();
      let sum = 0;
      for (let i = 0; i < 20; i++) {
        sum = dart.notNull(sum) + dart.notNull(a.foo());
        sum = dart.notNull(sum) + dart.notNull(b.foo());
      }
      let c = new inline_getter_test.C();
      sum = dart.notNull(sum) + dart.notNull(c.foo());
      expect$.Expect.equals(70, sum);
    }
  };
  dart.setSignature(inline_getter_test.InlineGetterTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  inline_getter_test.main = function() {
    inline_getter_test.InlineGetterTest.testMain();
  };
  dart.fn(inline_getter_test.main, VoidTodynamic());
  // Exports:
  exports.inline_getter_test = inline_getter_test;
});
