dart_library.library('language/compile_time_constant_checked2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__compile_time_constant_checked2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const compile_time_constant_checked2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_checked2_test_none_multi.A = class A extends core.Object {
    a2(x) {
      this.x = x;
    }
    a6(x) {
      this.x = x;
    }
  };
  dart.defineNamedConstructor(compile_time_constant_checked2_test_none_multi.A, 'a2');
  dart.defineNamedConstructor(compile_time_constant_checked2_test_none_multi.A, 'a6');
  dart.setSignature(compile_time_constant_checked2_test_none_multi.A, {
    constructors: () => ({
      a2: dart.definiteFunctionType(compile_time_constant_checked2_test_none_multi.A, [core.int]),
      a6: dart.definiteFunctionType(compile_time_constant_checked2_test_none_multi.A, [core.int])
    })
  });
  compile_time_constant_checked2_test_none_multi.main = function() {
  };
  dart.fn(compile_time_constant_checked2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_checked2_test_none_multi = compile_time_constant_checked2_test_none_multi;
});
