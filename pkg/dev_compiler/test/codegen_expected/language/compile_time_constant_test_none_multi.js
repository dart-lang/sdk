dart_library.library('language/compile_time_constant_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__compile_time_constant_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const compile_time_constant_test_none_multi = Object.create(null);
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_test_none_multi.Bad = class Bad extends core.Object {
    new() {
      this.foo = null;
      this.bar = -1;
    }
  };
  compile_time_constant_test_none_multi.Bad.toto = -3;
  compile_time_constant_test_none_multi.use = function(x) {
  };
  dart.fn(compile_time_constant_test_none_multi.use, dynamicTovoid());
  compile_time_constant_test_none_multi.main = function() {
    compile_time_constant_test_none_multi.use(new compile_time_constant_test_none_multi.Bad().bar);
    compile_time_constant_test_none_multi.use(compile_time_constant_test_none_multi.Bad.toto);
  };
  dart.fn(compile_time_constant_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_test_none_multi = compile_time_constant_test_none_multi;
});
