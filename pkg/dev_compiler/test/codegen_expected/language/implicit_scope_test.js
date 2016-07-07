dart_library.library('language/implicit_scope_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__implicit_scope_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const implicit_scope_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  implicit_scope_test.ImplicitScopeTest = class ImplicitScopeTest extends core.Object {
    static alwaysTrue() {
      return 1 + 1 == 2;
    }
    static testMain() {
      let a = "foo";
      let b = null;
      if (dart.test(implicit_scope_test.ImplicitScopeTest.alwaysTrue())) {
        let a = "bar";
      } else {
        let b = a;
      }
      expect$.Expect.equals("foo", a);
      expect$.Expect.equals(null, b);
      while (!dart.test(implicit_scope_test.ImplicitScopeTest.alwaysTrue())) {
        let a = "bar", b = "baz";
      }
      expect$.Expect.equals("foo", a);
      expect$.Expect.equals(null, b);
      for (let i = 0; i < 10; i++) {
        let a = "bar", b = "baz";
      }
      expect$.Expect.equals("foo", a);
      expect$.Expect.equals(null, b);
      do {
        let a = "bar", b = "baz";
      } while ("black" == "white");
      expect$.Expect.equals("foo", a);
      expect$.Expect.equals(null, b);
    }
  };
  dart.setSignature(implicit_scope_test.ImplicitScopeTest, {
    statics: () => ({
      alwaysTrue: dart.definiteFunctionType(core.bool, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['alwaysTrue', 'testMain']
  });
  implicit_scope_test.main = function() {
    implicit_scope_test.ImplicitScopeTest.testMain();
  };
  dart.fn(implicit_scope_test.main, VoidTodynamic());
  // Exports:
  exports.implicit_scope_test = implicit_scope_test;
});
