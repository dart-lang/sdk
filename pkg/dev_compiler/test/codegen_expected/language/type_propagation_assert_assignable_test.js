dart_library.library('language/type_propagation_assert_assignable_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_propagation_assert_assignable_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_propagation_assert_assignable_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _b = Symbol('_b');
  type_propagation_assert_assignable_test.A = class A extends core.Object {
    b() {
      try {
        return this[_b];
      } catch (e) {
      }

    }
    new(p, b) {
      this.p = p;
      this[_b] = b;
    }
  };
  dart.setSignature(type_propagation_assert_assignable_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(type_propagation_assert_assignable_test.A, [dart.dynamic, dart.dynamic])}),
    methods: () => ({b: dart.definiteFunctionType(dart.dynamic, [])})
  });
  type_propagation_assert_assignable_test.B = class B extends type_propagation_assert_assignable_test.A {
    new(p, b) {
      super.new(p, b);
    }
  };
  dart.setSignature(type_propagation_assert_assignable_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(type_propagation_assert_assignable_test.B, [dart.dynamic, dart.dynamic])})
  });
  type_propagation_assert_assignable_test.bar = function(v) {
    for (let x = v; x != null; x = dart.dload(x, 'p')) {
      if (dart.test(dart.dsend(x, 'b'))) {
        return x;
      }
    }
    return null;
  };
  dart.fn(type_propagation_assert_assignable_test.bar, dynamicTodynamic());
  type_propagation_assert_assignable_test.foo = function(v) {
    let x = type_propagation_assert_assignable_test.A._check(type_propagation_assert_assignable_test.bar(v));
    return x != null;
  };
  dart.fn(type_propagation_assert_assignable_test.foo, dynamicTodynamic());
  type_propagation_assert_assignable_test.main = function() {
    let a = new type_propagation_assert_assignable_test.A(new type_propagation_assert_assignable_test.B(new type_propagation_assert_assignable_test.A("haha", true), false), false);
    for (let i = 0; i < 20; i++) {
      expect$.Expect.isTrue(type_propagation_assert_assignable_test.foo(a));
    }
    expect$.Expect.isTrue(type_propagation_assert_assignable_test.foo(a));
  };
  dart.fn(type_propagation_assert_assignable_test.main, VoidTodynamic());
  // Exports:
  exports.type_propagation_assert_assignable_test = type_propagation_assert_assignable_test;
});
