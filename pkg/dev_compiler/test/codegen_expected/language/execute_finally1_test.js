dart_library.library('language/execute_finally1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__execute_finally1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const execute_finally1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  execute_finally1_test.Helper = class Helper extends core.Object {
    new() {
      this.i = 0;
    }
    f1() {
      try {
        let j = null;
        j = execute_finally1_test.Helper.func();
        this.i = 1;
        return this.i;
      } finally {
        this.i = dart.notNull(this.i) + 800;
      }
      return dart.notNull(this.i) + 200;
    }
    static func() {
      let i = 0;
      while (i < 10) {
        i++;
      }
      return i;
    }
  };
  dart.setSignature(execute_finally1_test.Helper, {
    constructors: () => ({new: dart.definiteFunctionType(execute_finally1_test.Helper, [])}),
    methods: () => ({f1: dart.definiteFunctionType(core.int, [])}),
    statics: () => ({func: dart.definiteFunctionType(core.int, [])}),
    names: ['func']
  });
  execute_finally1_test.ExecuteFinally1Test = class ExecuteFinally1Test extends core.Object {
    static testMain() {
      let obj = new execute_finally1_test.Helper();
      expect$.Expect.equals(1, obj.f1());
      expect$.Expect.equals(801, obj.i);
    }
  };
  dart.setSignature(execute_finally1_test.ExecuteFinally1Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  execute_finally1_test.main = function() {
    execute_finally1_test.ExecuteFinally1Test.testMain();
  };
  dart.fn(execute_finally1_test.main, VoidTodynamic());
  // Exports:
  exports.execute_finally1_test = execute_finally1_test;
});
