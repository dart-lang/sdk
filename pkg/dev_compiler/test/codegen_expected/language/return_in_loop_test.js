dart_library.library('language/return_in_loop_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__return_in_loop_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const return_in_loop_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  return_in_loop_test.A = class A extends core.Object {
    foo() {
      let x = 0;
      while (true) {
        if (true) {
          return 42;
        } else {
        }
        x = core.int._check(this.bar());
      }
    }
    bar() {
      return 1;
    }
  };
  dart.setSignature(return_in_loop_test.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  return_in_loop_test.main = function() {
    expect$.Expect.equals(42, new return_in_loop_test.A().foo());
  };
  dart.fn(return_in_loop_test.main, VoidTodynamic());
  // Exports:
  exports.return_in_loop_test = return_in_loop_test;
});
