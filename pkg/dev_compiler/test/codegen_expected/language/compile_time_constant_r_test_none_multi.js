dart_library.library('language/compile_time_constant_r_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__compile_time_constant_r_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const compile_time_constant_r_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_r_test_none_multi.x = "x";
  compile_time_constant_r_test_none_multi.y = dart.const(dart.map([0, "y"]));
  compile_time_constant_r_test_none_multi.main = function() {
    core.print(compile_time_constant_r_test_none_multi.x);
    core.print(compile_time_constant_r_test_none_multi.y);
    let z = 1 + 1 + 1;
    core.print(z);
  };
  dart.fn(compile_time_constant_r_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_r_test_none_multi = compile_time_constant_r_test_none_multi;
});
