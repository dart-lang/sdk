dart_library.library('language/tree_shake_typed_selector_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__tree_shake_typed_selector_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const tree_shake_typed_selector_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  tree_shake_typed_selector_test.A = class A extends core.Object {
    static new() {
      return new tree_shake_typed_selector_test.B();
    }
    foo() {
      return 0;
    }
  };
  dart.setSignature(tree_shake_typed_selector_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(tree_shake_typed_selector_test.A, [])}),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  tree_shake_typed_selector_test.B = class B extends core.Object {
    foo() {
      return 42;
    }
  };
  tree_shake_typed_selector_test.B[dart.implements] = () => [tree_shake_typed_selector_test.A];
  dart.setSignature(tree_shake_typed_selector_test.B, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  tree_shake_typed_selector_test.main = function() {
    let a = tree_shake_typed_selector_test.A.new();
    if (tree_shake_typed_selector_test.A.is(a)) {
      expect$.Expect.equals(42, a.foo());
    } else {
      expect$.Expect.fail('Should not be here');
    }
  };
  dart.fn(tree_shake_typed_selector_test.main, VoidTodynamic());
  // Exports:
  exports.tree_shake_typed_selector_test = tree_shake_typed_selector_test;
});
