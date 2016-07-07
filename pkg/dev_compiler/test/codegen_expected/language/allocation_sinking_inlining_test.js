dart_library.library('language/allocation_sinking_inlining_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__allocation_sinking_inlining_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const allocation_sinking_inlining_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  allocation_sinking_inlining_test.A = class A extends core.Object {
    foo(x) {
      return dart.dput(x, 'f', dart.dsend(dart.dload(x, 'f'), '+', 1));
    }
  };
  dart.setSignature(allocation_sinking_inlining_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  allocation_sinking_inlining_test.B = class B extends core.Object {
    foo(x) {
      return dart.dput(x, 'f', dart.dsend(dart.dload(x, 'f'), '-', 1));
    }
  };
  dart.setSignature(allocation_sinking_inlining_test.B, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  allocation_sinking_inlining_test.C = class C extends core.Object {
    new() {
      this.f = 0;
    }
  };
  allocation_sinking_inlining_test.test = function(obj) {
    let c = new allocation_sinking_inlining_test.C();
    return dart.dsend(obj, 'foo', c);
  };
  dart.fn(allocation_sinking_inlining_test.test, dynamicTodynamic());
  allocation_sinking_inlining_test.main = function() {
    let a = new allocation_sinking_inlining_test.A();
    let b = new allocation_sinking_inlining_test.B();
    expect$.Expect.equals(1, allocation_sinking_inlining_test.test(a));
    expect$.Expect.equals(-1, allocation_sinking_inlining_test.test(b));
    for (let i = 0; i < 20; i++)
      allocation_sinking_inlining_test.test(a);
    expect$.Expect.equals(1, allocation_sinking_inlining_test.test(a));
    expect$.Expect.equals(-1, allocation_sinking_inlining_test.test(b));
  };
  dart.fn(allocation_sinking_inlining_test.main, VoidTodynamic());
  // Exports:
  exports.allocation_sinking_inlining_test = allocation_sinking_inlining_test;
});
