dart_library.library('language/static_postfix_operator_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__static_postfix_operator_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const static_postfix_operator_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  static_postfix_operator_test.a = 0;
  static_postfix_operator_test.b = 0;
  static_postfix_operator_test.withTryFinally = function() {
    let inIt = false;
    try {
      if ((() => {
        let x = static_postfix_operator_test.a;
        static_postfix_operator_test.a = dart.notNull(x) + 1;
        return x;
      })() == 0) {
        inIt = true;
      }
    } finally {
    }
    expect$.Expect.isTrue(inIt);
  };
  dart.fn(static_postfix_operator_test.withTryFinally, VoidTodynamic());
  static_postfix_operator_test.withoutTryFinally = function() {
    let inIt = false;
    if ((() => {
      let x = static_postfix_operator_test.b;
      static_postfix_operator_test.b = dart.notNull(x) + 1;
      return x;
    })() == 0) {
      inIt = true;
    }
    expect$.Expect.isTrue(inIt);
  };
  dart.fn(static_postfix_operator_test.withoutTryFinally, VoidTodynamic());
  static_postfix_operator_test.main = function() {
    static_postfix_operator_test.withTryFinally();
    static_postfix_operator_test.withoutTryFinally();
  };
  dart.fn(static_postfix_operator_test.main, VoidTodynamic());
  // Exports:
  exports.static_postfix_operator_test = static_postfix_operator_test;
});
