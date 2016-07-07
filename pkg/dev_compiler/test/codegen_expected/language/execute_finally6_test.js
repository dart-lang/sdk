dart_library.library('language/execute_finally6_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__execute_finally6_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const execute_finally6_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  execute_finally6_test.Helper = class Helper extends core.Object {
    new() {
      this.i = 0;
    }
    f1() {
      try {
        try {
          let j = null;
          j = execute_finally6_test.Helper.func();
          L1:
            while (dart.notNull(this.i) <= 0) {
              if (this.i == 0) {
                try {
                  this.i = 1;
                  execute_finally6_test.Helper.func();
                  try {
                    let j = null;
                    j = execute_finally6_test.Helper.func();
                    L1:
                      while (dart.notNull(j) < 50) {
                        j = dart.notNull(j) + dart.notNull(execute_finally6_test.Helper.func());
                        if (dart.notNull(j) > 30) {
                          break L1;
                        }
                      }
                    this.i = dart.notNull(this.i) + 200000;
                  } finally {
                    this.i = dart.notNull(this.i) + 200;
                  }
                } finally {
                  this.i = dart.notNull(this.i) + 400;
                }
              }
            }
        } finally {
          this.i = dart.notNull(this.i) + 800;
        }
        return this.i;
      } finally {
        this.i = dart.notNull(this.i) + 1600;
      }
      this.i = dart.notNull(this.i) + 2000000;
      return 1;
    }
    static func() {
      let i = 0;
      while (i < 10) {
        i++;
      }
      return i;
    }
  };
  dart.setSignature(execute_finally6_test.Helper, {
    constructors: () => ({new: dart.definiteFunctionType(execute_finally6_test.Helper, [])}),
    methods: () => ({f1: dart.definiteFunctionType(core.int, [])}),
    statics: () => ({func: dart.definiteFunctionType(core.int, [])}),
    names: ['func']
  });
  execute_finally6_test.ExecuteFinally6Test = class ExecuteFinally6Test extends core.Object {
    static testMain() {
      let obj = new execute_finally6_test.Helper();
      expect$.Expect.equals(201401, obj.f1());
      expect$.Expect.equals(203001, obj.i);
    }
  };
  dart.setSignature(execute_finally6_test.ExecuteFinally6Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  execute_finally6_test.main = function() {
    execute_finally6_test.ExecuteFinally6Test.testMain();
  };
  dart.fn(execute_finally6_test.main, VoidTodynamic());
  // Exports:
  exports.execute_finally6_test = execute_finally6_test;
});
