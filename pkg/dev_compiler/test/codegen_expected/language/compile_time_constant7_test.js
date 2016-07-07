dart_library.library('language/compile_time_constant7_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant7_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant7_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant7_test.A = class A extends core.Object {
    new() {
    }
    toString() {
      return "a";
    }
  };
  dart.setSignature(compile_time_constant7_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant7_test.A, [])})
  });
  compile_time_constant7_test.a = dart.const(new compile_time_constant7_test.A());
  compile_time_constant7_test.main = function() {
    expect$.Expect.equals("a", compile_time_constant7_test.a.toString());
  };
  dart.fn(compile_time_constant7_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant7_test = compile_time_constant7_test;
});
