dart_library.library('language/compile_time_constant_c_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__compile_time_constant_c_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const compile_time_constant_c_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_c_test_none_multi.m0 = dart.const(dart.map([499, 400 + 99], core.int, core.int));
  compile_time_constant_c_test_none_multi.m1 = dart.const(dart.map());
  compile_time_constant_c_test_none_multi.m2 = dart.const(dart.map());
  compile_time_constant_c_test_none_multi.m3 = dart.const(dart.map());
  compile_time_constant_c_test_none_multi.use = function(x) {
    return x;
  };
  dart.fn(compile_time_constant_c_test_none_multi.use, dynamicTodynamic());
  compile_time_constant_c_test_none_multi.main = function() {
    compile_time_constant_c_test_none_multi.use(compile_time_constant_c_test_none_multi.m0);
    compile_time_constant_c_test_none_multi.use(compile_time_constant_c_test_none_multi.m1);
    compile_time_constant_c_test_none_multi.use(compile_time_constant_c_test_none_multi.m2);
    compile_time_constant_c_test_none_multi.use(compile_time_constant_c_test_none_multi.m3);
  };
  dart.fn(compile_time_constant_c_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_c_test_none_multi = compile_time_constant_c_test_none_multi;
});
