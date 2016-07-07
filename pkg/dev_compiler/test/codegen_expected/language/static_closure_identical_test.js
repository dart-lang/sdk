dart_library.library('language/static_closure_identical_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__static_closure_identical_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const static_closure_identical_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  static_closure_identical_test.main = function() {
    expect$.Expect.equals(static_closure_identical_test.main, static_closure_identical_test.main);
    expect$.Expect.identical(static_closure_identical_test.main, static_closure_identical_test.main);
    expect$.Expect.equals(dart.hashCode(static_closure_identical_test.main), dart.hashCode(static_closure_identical_test.main));
    expect$.Expect.equals(static_closure_identical_test.main, static_closure_identical_test.foo);
    expect$.Expect.identical(static_closure_identical_test.main, static_closure_identical_test.foo);
    expect$.Expect.equals(dart.hashCode(static_closure_identical_test.main), dart.hashCode(static_closure_identical_test.foo));
  };
  dart.fn(static_closure_identical_test.main, VoidTodynamic());
  static_closure_identical_test.foo = static_closure_identical_test.main;
  // Exports:
  exports.static_closure_identical_test = static_closure_identical_test;
});
