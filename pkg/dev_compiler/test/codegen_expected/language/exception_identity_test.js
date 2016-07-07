dart_library.library('language/exception_identity_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__exception_identity_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const exception_identity_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  exception_identity_test.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(exception_identity_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(exception_identity_test.A, [])})
  });
  exception_identity_test.check = function(exception) {
    try {
      dart.throw(exception);
    } catch (e) {
      expect$.Expect.equals(exception, e);
    }

  };
  dart.fn(exception_identity_test.check, dynamicTodynamic());
  exception_identity_test.main = function() {
    exception_identity_test.check("str");
    exception_identity_test.check(new exception_identity_test.A());
    exception_identity_test.check(1);
    exception_identity_test.check(1.2);
  };
  dart.fn(exception_identity_test.main, VoidTodynamic());
  // Exports:
  exports.exception_identity_test = exception_identity_test;
});
