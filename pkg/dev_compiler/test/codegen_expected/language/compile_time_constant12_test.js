dart_library.library('language/compile_time_constant12_test', null, /* Imports */[
  'dart_sdk'
], function load__compile_time_constant12_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const compile_time_constant12_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant12_test.s = "foo";
  compile_time_constant12_test.i = compile_time_constant12_test.s[dartx.length];
  compile_time_constant12_test.l = dart.notNull("foo"[dartx.length]) + 1;
  compile_time_constant12_test.use = function(x) {
    return x;
  };
  dart.fn(compile_time_constant12_test.use, dynamicTodynamic());
  compile_time_constant12_test.main = function() {
    compile_time_constant12_test.use(compile_time_constant12_test.s);
    compile_time_constant12_test.use(compile_time_constant12_test.i);
    compile_time_constant12_test.use(compile_time_constant12_test.l);
  };
  dart.fn(compile_time_constant12_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant12_test = compile_time_constant12_test;
});
