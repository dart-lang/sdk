dart_library.library('language/compile_time_constant_k_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_k_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_k_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_k_test_none_multi.x = dart.const(dart.map({a: 4}));
  compile_time_constant_k_test_none_multi.z = dart.const(dart.map({__proto__: 499}));
  compile_time_constant_k_test_none_multi.x2 = dart.const(dart.map({a: 4}));
  compile_time_constant_k_test_none_multi.y2 = dart.const(dart.map({a: 14, b: 13}));
  compile_time_constant_k_test_none_multi.z2 = dart.const(dart.map({__proto__: 499}));
  compile_time_constant_k_test_none_multi.main = function() {
    expect$.Expect.identical(compile_time_constant_k_test_none_multi.x2, compile_time_constant_k_test_none_multi.x);
    expect$.Expect.identical(compile_time_constant_k_test_none_multi.z2, compile_time_constant_k_test_none_multi.z);
  };
  dart.fn(compile_time_constant_k_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_k_test_none_multi = compile_time_constant_k_test_none_multi;
});
