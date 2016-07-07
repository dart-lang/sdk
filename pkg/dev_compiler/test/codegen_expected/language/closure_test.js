dart_library.library('language/closure_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_test.A = class A extends core.Object {
    new(field) {
      this.field = field;
    }
  };
  dart.setSignature(closure_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(closure_test.A, [dart.dynamic])})
  });
  closure_test.ClosureTest = class ClosureTest extends core.Object {
    static testMain() {
      let o = new closure_test.A(3);
      function foo() {
        return (() => {
          let x = o.field;
          o.field = dart.dsend(x, '+', 1);
          return x;
        })();
      }
      dart.fn(foo, VoidTodynamic());
      expect$.Expect.equals(3, foo());
      expect$.Expect.equals(4, o.field);
    }
  };
  dart.setSignature(closure_test.ClosureTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  closure_test.main = function() {
    closure_test.ClosureTest.testMain();
  };
  dart.fn(closure_test.main, VoidTodynamic());
  // Exports:
  exports.closure_test = closure_test;
});
