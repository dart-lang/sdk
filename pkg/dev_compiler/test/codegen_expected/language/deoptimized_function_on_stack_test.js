dart_library.library('language/deoptimized_function_on_stack_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deoptimized_function_on_stack_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deoptimized_function_on_stack_test = Object.create(null);
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(deoptimized_function_on_stack_test.A)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let ListAndintTodynamic = () => (ListAndintTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List, core.int])))();
  deoptimized_function_on_stack_test.main = function() {
    deoptimized_function_on_stack_test.warmup();
    deoptimized_function_on_stack_test.runTest();
  };
  dart.fn(deoptimized_function_on_stack_test.main, VoidTodynamic());
  deoptimized_function_on_stack_test.warmup = function() {
    let a = JSArrayOfA().of([new deoptimized_function_on_stack_test.A(), new deoptimized_function_on_stack_test.A(), new deoptimized_function_on_stack_test.A(), new deoptimized_function_on_stack_test.A()]);
    let res = 0;
    for (let i = 0; i < 20; i++) {
      res = core.int._check(deoptimized_function_on_stack_test.call(a, 0));
    }
    expect$.Expect.equals(10, res);
  };
  dart.fn(deoptimized_function_on_stack_test.warmup, VoidTodynamic());
  deoptimized_function_on_stack_test.runTest = function() {
    let a = JSArrayOfObject().of([new deoptimized_function_on_stack_test.A(), new deoptimized_function_on_stack_test.A(), new deoptimized_function_on_stack_test.B(), new deoptimized_function_on_stack_test.A(), new deoptimized_function_on_stack_test.B(), new deoptimized_function_on_stack_test.B()]);
    let res = deoptimized_function_on_stack_test.call(a, 0);
    expect$.Expect.equals(35, res);
  };
  dart.fn(deoptimized_function_on_stack_test.runTest, VoidTodynamic());
  deoptimized_function_on_stack_test.call = function(a, n) {
    if (dart.notNull(n) < dart.notNull(a[dartx.length])) {
      let sum = deoptimized_function_on_stack_test.call(a, dart.notNull(n) + 1);
      for (let i = n; dart.notNull(i) < dart.notNull(a[dartx.length]); i = dart.notNull(i) + 1) {
        sum = dart.dsend(sum, '+', dart.dsend(a[dartx.get](i), 'foo'));
      }
      return sum;
    }
    return 0;
  };
  dart.fn(deoptimized_function_on_stack_test.call, ListAndintTodynamic());
  deoptimized_function_on_stack_test.A = class A extends core.Object {
    foo() {
      return 1;
    }
  };
  dart.setSignature(deoptimized_function_on_stack_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  deoptimized_function_on_stack_test.B = class B extends core.Object {
    foo() {
      return 2;
    }
  };
  dart.setSignature(deoptimized_function_on_stack_test.B, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  // Exports:
  exports.deoptimized_function_on_stack_test = deoptimized_function_on_stack_test;
});
