dart_library.library('corelib/hashcode_boxed_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__hashcode_boxed_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const hashcode_boxed_test = Object.create(null);
  let doubleTodouble = () => (doubleTodouble = dart.constFn(dart.definiteFunctionType(core.double, [core.double])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  hashcode_boxed_test.fib = function(n) {
    return dart.notNull(n) <= 1.0 ? 1.0 : dart.notNull(hashcode_boxed_test.fib(dart.notNull(n) - 1)) + dart.notNull(hashcode_boxed_test.fib(dart.notNull(n) - 2));
  };
  dart.fn(hashcode_boxed_test.fib, doubleTodouble());
  hashcode_boxed_test.main = function() {
    let a = dart.notNull(hashcode_boxed_test.fib(5.0)) + 1.0;
    let b = dart.notNull(hashcode_boxed_test.fib(4.0)) + 4.0;
    expect$.Expect.isTrue(core.identical(a, b));
    expect$.Expect.equals(core.identityHashCode(a), core.identityHashCode(b));
    expect$.Expect.equals(a, b);
    expect$.Expect.equals(dart.hashCode(a), dart.hashCode(b));
  };
  dart.fn(hashcode_boxed_test.main, VoidTodynamic());
  // Exports:
  exports.hashcode_boxed_test = hashcode_boxed_test;
});
