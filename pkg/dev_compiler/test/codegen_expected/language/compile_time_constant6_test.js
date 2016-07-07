dart_library.library('language/compile_time_constant6_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant6_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant6_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant6_test.g1 = true;
  compile_time_constant6_test.g2 = 499;
  compile_time_constant6_test.g3 = "foo";
  compile_time_constant6_test.g4 = 3.3;
  compile_time_constant6_test.g5 = dart.equals(compile_time_constant6_test.g1, compile_time_constant6_test.g2);
  compile_time_constant6_test.g6 = dart.equals(compile_time_constant6_test.g1, compile_time_constant6_test.g3);
  compile_time_constant6_test.g7 = dart.equals(compile_time_constant6_test.g1, compile_time_constant6_test.g4);
  compile_time_constant6_test.g8 = dart.equals(compile_time_constant6_test.g2, compile_time_constant6_test.g3);
  compile_time_constant6_test.g9 = compile_time_constant6_test.g2 == compile_time_constant6_test.g4;
  compile_time_constant6_test.g10 = dart.equals(compile_time_constant6_test.g3, compile_time_constant6_test.g4);
  compile_time_constant6_test.g11 = compile_time_constant6_test.g1 == compile_time_constant6_test.g1;
  compile_time_constant6_test.g12 = compile_time_constant6_test.g2 == compile_time_constant6_test.g2;
  compile_time_constant6_test.g13 = compile_time_constant6_test.g3 == compile_time_constant6_test.g3;
  compile_time_constant6_test.g14 = compile_time_constant6_test.g4 == compile_time_constant6_test.g4;
  compile_time_constant6_test.main = function() {
    expect$.Expect.isFalse(compile_time_constant6_test.g5);
    expect$.Expect.isFalse(compile_time_constant6_test.g6);
    expect$.Expect.isFalse(compile_time_constant6_test.g7);
    expect$.Expect.isFalse(compile_time_constant6_test.g8);
    expect$.Expect.isFalse(compile_time_constant6_test.g9);
    expect$.Expect.isFalse(compile_time_constant6_test.g10);
    expect$.Expect.isTrue(compile_time_constant6_test.g11);
    expect$.Expect.isTrue(compile_time_constant6_test.g12);
    expect$.Expect.isTrue(compile_time_constant6_test.g13);
    expect$.Expect.isTrue(compile_time_constant6_test.g14);
  };
  dart.fn(compile_time_constant6_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant6_test = compile_time_constant6_test;
});
