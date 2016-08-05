dart_library.library('language/context_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__context_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const context_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  context_test.ContextTest = class ContextTest extends core.Object {
    static foo(f) {
      return dart.dcall(f);
    }
    static testMain() {
      let x = 42;
      function bar() {
        return x;
      }
      dart.fn(bar, VoidToint());
      x++;
      expect$.Expect.equals(43, context_test.ContextTest.foo(bar));
    }
  };
  dart.setSignature(context_test.ContextTest, {
    statics: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, [core.Function]),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['foo', 'testMain']
  });
  context_test.main = function() {
    context_test.ContextTest.testMain();
  };
  dart.fn(context_test.main, VoidTodynamic());
  // Exports:
  exports.context_test = context_test;
});
