dart_library.library('language/function_getter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_getter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_getter_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_getter_test.A = class A extends core.Object {
    a() {
      return 42;
    }
  };
  dart.setSignature(function_getter_test.A, {
    methods: () => ({a: dart.definiteFunctionType(dart.dynamic, [])})
  });
  function_getter_test.main = function() {
    expect$.Expect.equals(new function_getter_test.A().a(), dart.bind(new function_getter_test.A(), 'a')());
  };
  dart.fn(function_getter_test.main, VoidTodynamic());
  // Exports:
  exports.function_getter_test = function_getter_test;
});
