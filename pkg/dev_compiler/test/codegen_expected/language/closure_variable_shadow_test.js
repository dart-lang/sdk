dart_library.library('language/closure_variable_shadow_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_variable_shadow_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_variable_shadow_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_variable_shadow_test.foo = function(x) {
    let y = x;
    function bar(x) {
      return dart.dsend(y, '-', x);
    }
    dart.fn(bar, dynamicTodynamic());
    return bar;
  };
  dart.fn(closure_variable_shadow_test.foo, dynamicTodynamic());
  closure_variable_shadow_test.main = function() {
    expect$.Expect.equals(-10, dart.dcall(closure_variable_shadow_test.foo(10), 20));
  };
  dart.fn(closure_variable_shadow_test.main, VoidTodynamic());
  // Exports:
  exports.closure_variable_shadow_test = closure_variable_shadow_test;
});
