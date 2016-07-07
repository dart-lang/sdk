dart_library.library('language/function_field_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_field_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_field_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_field_test.Wrapper = class Wrapper extends core.Object {
    new() {
      this.f = null;
    }
  };
  function_field_test.main = function() {
    let w = new function_field_test.Wrapper();
    w.f = dart.fn(() => 42, VoidToint());
    expect$.Expect.equals(42, dart.dsend(w, 'f'));
  };
  dart.fn(function_field_test.main, VoidTodynamic());
  // Exports:
  exports.function_field_test = function_field_test;
});
