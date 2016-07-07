dart_library.library('language/compile_time_constant13_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__compile_time_constant13_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const compile_time_constant13_test_01_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant13_test_01_multi.A = class A extends core.Object {
    new() {
      this.x = 'foo';
    }
  };
  dart.setSignature(compile_time_constant13_test_01_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant13_test_01_multi.A, [])})
  });
  compile_time_constant13_test_01_multi.use = function(x) {
    return x;
  };
  dart.fn(compile_time_constant13_test_01_multi.use, dynamicTodynamic());
  compile_time_constant13_test_01_multi.a = dart.const(new compile_time_constant13_test_01_multi.A());
  compile_time_constant13_test_01_multi.main = function() {
    compile_time_constant13_test_01_multi.use(compile_time_constant13_test_01_multi.a);
  };
  dart.fn(compile_time_constant13_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant13_test_01_multi = compile_time_constant13_test_01_multi;
});
