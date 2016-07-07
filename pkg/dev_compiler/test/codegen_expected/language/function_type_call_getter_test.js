dart_library.library('language/function_type_call_getter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_type_call_getter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_type_call_getter_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_call_getter_test.A = class A extends core.Object {
    new() {
      this.call = null;
    }
  };
  function_type_call_getter_test.B = class B extends core.Object {
    get call() {
      return null;
    }
  };
  function_type_call_getter_test.C = class C extends core.Object {
    set call(x) {}
  };
  function_type_call_getter_test.F = dart.typedef('F', () => dart.functionType(core.int, [core.String]));
  function_type_call_getter_test.main = function() {
    expect$.Expect.isFalse(core.Function.is(new function_type_call_getter_test.A()));
    expect$.Expect.isFalse(core.Function.is(new function_type_call_getter_test.B()));
    expect$.Expect.isFalse(core.Function.is(new function_type_call_getter_test.C()));
    expect$.Expect.isFalse(function_type_call_getter_test.F.is(new function_type_call_getter_test.A()));
    expect$.Expect.isFalse(function_type_call_getter_test.F.is(new function_type_call_getter_test.B()));
    expect$.Expect.isFalse(function_type_call_getter_test.F.is(new function_type_call_getter_test.C()));
  };
  dart.fn(function_type_call_getter_test.main, VoidTodynamic());
  // Exports:
  exports.function_type_call_getter_test = function_type_call_getter_test;
});
