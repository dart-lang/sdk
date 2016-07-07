dart_library.library('language/execute_finally12_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__execute_finally12_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const execute_finally12_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  execute_finally12_test.a = null;
  execute_finally12_test.foo = function() {
    let b = dart.equals(execute_finally12_test.a, 8);
    while (!b) {
      try {
        try {
        } finally {
          execute_finally12_test.a = 8;
          break;
        }
      } finally {
        return dart.equals(execute_finally12_test.a, 8);
      }
    }
  };
  dart.fn(execute_finally12_test.foo, VoidTodynamic());
  execute_finally12_test.main = function() {
    expect$.Expect.isTrue(execute_finally12_test.foo());
  };
  dart.fn(execute_finally12_test.main, VoidTodynamic());
  // Exports:
  exports.execute_finally12_test = execute_finally12_test;
});
