dart_library.library('language/compile_time_constant5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant5_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant5_test.x = true;
  compile_time_constant5_test.g1 = !true;
  compile_time_constant5_test.g2 = !compile_time_constant5_test.g1;
  compile_time_constant5_test.main = function() {
    expect$.Expect.equals(false, compile_time_constant5_test.g1);
    expect$.Expect.equals(true, compile_time_constant5_test.g2);
  };
  dart.fn(compile_time_constant5_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant5_test = compile_time_constant5_test;
});
