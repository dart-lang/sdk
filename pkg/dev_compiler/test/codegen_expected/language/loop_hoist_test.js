dart_library.library('language/loop_hoist_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__loop_hoist_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const loop_hoist_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  loop_hoist_test.A = class A extends core.Object {
    new() {
      this.x = 0;
    }
    bar() {
      for (let i = 1; i < 3; i++) {
        this.setX(499);
        loop_hoist_test.foo(this.x);
        break;
      }
    }
    setX(x) {
      return this.x = core.num._check(x);
    }
  };
  dart.setSignature(loop_hoist_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(loop_hoist_test.A, [])}),
    methods: () => ({
      bar: dart.definiteFunctionType(dart.void, []),
      setX: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  loop_hoist_test.saved = null;
  loop_hoist_test.foo = function(x) {
    return loop_hoist_test.saved = x;
  };
  dart.fn(loop_hoist_test.foo, dynamicTodynamic());
  loop_hoist_test.main = function() {
    let a = new loop_hoist_test.A();
    for (let i = 0; i < 1; i++) {
      a.bar();
    }
    expect$.Expect.equals(499, loop_hoist_test.saved);
  };
  dart.fn(loop_hoist_test.main, VoidTodynamic());
  // Exports:
  exports.loop_hoist_test = loop_hoist_test;
});
