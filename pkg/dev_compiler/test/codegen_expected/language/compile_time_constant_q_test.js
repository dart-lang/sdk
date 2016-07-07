dart_library.library('language/compile_time_constant_q_test', null, /* Imports */[
  'dart_sdk'
], function load__compile_time_constant_q_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const compile_time_constant_q_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_q_test.x = 14.0;
  compile_time_constant_q_test.main = function() {
    core.print(compile_time_constant_q_test.x);
  };
  dart.fn(compile_time_constant_q_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_q_test = compile_time_constant_q_test;
});
