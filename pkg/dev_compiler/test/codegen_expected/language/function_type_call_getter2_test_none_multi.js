dart_library.library('language/function_type_call_getter2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__function_type_call_getter2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const function_type_call_getter2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_call_getter2_test_none_multi.A = class A extends core.Object {
    new() {
      this.call = null;
    }
  };
  function_type_call_getter2_test_none_multi.B = class B extends core.Object {
    get call() {
      return null;
    }
  };
  function_type_call_getter2_test_none_multi.C = class C extends core.Object {
    set call(x) {}
  };
  function_type_call_getter2_test_none_multi.F = dart.typedef('F', () => dart.functionType(core.int, [core.String]));
  function_type_call_getter2_test_none_multi.main = function() {
    let a = new function_type_call_getter2_test_none_multi.A();
    let b = new function_type_call_getter2_test_none_multi.B();
    let c = new function_type_call_getter2_test_none_multi.C();
    let a2 = a;
    let a3 = a;
    let b2 = b;
    let b3 = b;
    let c2 = c;
    let c3 = c;
  };
  dart.fn(function_type_call_getter2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.function_type_call_getter2_test_none_multi = function_type_call_getter2_test_none_multi;
});
