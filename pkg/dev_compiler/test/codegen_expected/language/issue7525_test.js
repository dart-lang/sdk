dart_library.library('language/issue7525_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue7525_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue7525_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue7525_test.foo = function() {
    let ol = JSArrayOfint().of([2]);
    ol[dartx.get](0);
    let x = ol[dartx.get](0);
    return x;
  };
  dart.fn(issue7525_test.foo, VoidTodynamic());
  issue7525_test.main = function() {
    for (let i = 0; i < 20; i++) {
      issue7525_test.foo();
    }
    expect$.Expect.equals(2, issue7525_test.foo());
  };
  dart.fn(issue7525_test.main, VoidTodynamic());
  // Exports:
  exports.issue7525_test = issue7525_test;
});
