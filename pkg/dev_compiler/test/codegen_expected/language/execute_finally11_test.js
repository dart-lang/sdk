dart_library.library('language/execute_finally11_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__execute_finally11_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const execute_finally11_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  execute_finally11_test.A = class A extends core.Object {
    new() {
      this.field = null;
    }
    start() {}
    stop() {
      this.field = 42;
    }
  };
  dart.setSignature(execute_finally11_test.A, {
    methods: () => ({
      start: dart.definiteFunctionType(dart.dynamic, []),
      stop: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  execute_finally11_test.B = class B extends core.Object {
    new() {
      this.totalCompileTime = new execute_finally11_test.A();
      this.runCompiler = new core.Object();
    }
    run() {
      this.totalCompileTime.start();
      try {
        dart.throw('foo');
      } catch (exception) {
        try {
          dart.toString(this.runCompiler);
          dart.toString(this.runCompiler);
        } catch (exception) {
        }

        throw exception;
      }
 finally {
        this.totalCompileTime.stop();
      }
    }
  };
  dart.setSignature(execute_finally11_test.B, {
    methods: () => ({run: dart.definiteFunctionType(dart.dynamic, [])})
  });
  execute_finally11_test.main = function() {
    let b = new execute_finally11_test.B();
    try {
      b.run();
      dart.throw('Expected exception');
    } catch (exception) {
    }

    expect$.Expect.equals(42, b.totalCompileTime.field);
  };
  dart.fn(execute_finally11_test.main, VoidTodynamic());
  // Exports:
  exports.execute_finally11_test = execute_finally11_test;
});
