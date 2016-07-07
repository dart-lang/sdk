dart_library.library('language/new_statement_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__new_statement_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const new_statement_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  new_statement_test.A = class A extends core.Object {
    new(x, y) {
      this.a = x;
      this.b = y;
      new_statement_test.A.c = x;
      new_statement_test.A.d = y;
    }
  };
  dart.setSignature(new_statement_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(new_statement_test.A, [core.int, core.int])})
  });
  new_statement_test.A.c = null;
  new_statement_test.A.d = null;
  new_statement_test.NewStatementTest = class NewStatementTest extends core.Object {
    static testMain() {
      new new_statement_test.A(10, 20);
      expect$.Expect.equals(10, new_statement_test.A.c);
      expect$.Expect.equals(20, new_statement_test.A.d);
    }
  };
  dart.setSignature(new_statement_test.NewStatementTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  new_statement_test.main = function() {
    new_statement_test.NewStatementTest.testMain();
  };
  dart.fn(new_statement_test.main, VoidTodynamic());
  // Exports:
  exports.new_statement_test = new_statement_test;
});
