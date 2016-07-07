dart_library.library('language/function_type_this_parameter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_type_this_parameter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_type_this_parameter_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_this_parameter_test.A = class A extends core.Object {
    new(f) {
      this.f = f;
    }
  };
  dart.setSignature(function_type_this_parameter_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(function_type_this_parameter_test.A, [dart.functionType(core.int, [])])})
  });
  function_type_this_parameter_test.main = function() {
    let a = new function_type_this_parameter_test.A(dart.fn(() => 499, VoidToint()));
    expect$.Expect.equals(499, dart.dcall(a.f));
  };
  dart.fn(function_type_this_parameter_test.main, VoidTodynamic());
  // Exports:
  exports.function_type_this_parameter_test = function_type_this_parameter_test;
});
