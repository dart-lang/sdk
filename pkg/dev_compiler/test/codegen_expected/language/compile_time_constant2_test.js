dart_library.library('language/compile_time_constant2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant2_test.x = 19;
  compile_time_constant2_test.y = 3;
  compile_time_constant2_test.z = -5;
  compile_time_constant2_test.g1 = compile_time_constant2_test.x + compile_time_constant2_test.y;
  compile_time_constant2_test.g2 = compile_time_constant2_test.x * compile_time_constant2_test.y;
  compile_time_constant2_test.g3 = compile_time_constant2_test.x / compile_time_constant2_test.y;
  compile_time_constant2_test.g4 = (compile_time_constant2_test.x / compile_time_constant2_test.y)[dartx.truncate]();
  compile_time_constant2_test.g5 = compile_time_constant2_test.x << compile_time_constant2_test.y;
  compile_time_constant2_test.g6 = compile_time_constant2_test.x >> compile_time_constant2_test.y;
  compile_time_constant2_test.g7 = ~compile_time_constant2_test.z >>> 0;
  compile_time_constant2_test.g8 = -compile_time_constant2_test.x;
  compile_time_constant2_test.g9 = compile_time_constant2_test.x < compile_time_constant2_test.y;
  compile_time_constant2_test.g10 = compile_time_constant2_test.x <= compile_time_constant2_test.y;
  compile_time_constant2_test.g11 = compile_time_constant2_test.x <= compile_time_constant2_test.x;
  compile_time_constant2_test.g12 = compile_time_constant2_test.x > compile_time_constant2_test.y;
  compile_time_constant2_test.g13 = compile_time_constant2_test.x >= compile_time_constant2_test.y;
  compile_time_constant2_test.g14 = compile_time_constant2_test.x >= compile_time_constant2_test.x;
  compile_time_constant2_test.g15 = compile_time_constant2_test.x == compile_time_constant2_test.y;
  compile_time_constant2_test.g16 = compile_time_constant2_test.x == compile_time_constant2_test.x;
  compile_time_constant2_test.g17 = compile_time_constant2_test.x != compile_time_constant2_test.y;
  compile_time_constant2_test.g18 = compile_time_constant2_test.x != compile_time_constant2_test.x;
  compile_time_constant2_test.g19 = compile_time_constant2_test.x | compile_time_constant2_test.y;
  compile_time_constant2_test.g20 = compile_time_constant2_test.x & compile_time_constant2_test.y;
  compile_time_constant2_test.g21 = compile_time_constant2_test.x ^ compile_time_constant2_test.y;
  compile_time_constant2_test.g22 = compile_time_constant2_test.g1 + compile_time_constant2_test.g2 + compile_time_constant2_test.g4 + compile_time_constant2_test.g5 + compile_time_constant2_test.g6 + compile_time_constant2_test.g7 + compile_time_constant2_test.g8;
  compile_time_constant2_test.g23 = compile_time_constant2_test.x[dartx['%']](compile_time_constant2_test.y);
  compile_time_constant2_test.main = function() {
    expect$.Expect.equals(22, compile_time_constant2_test.g1);
    expect$.Expect.equals(57, compile_time_constant2_test.g2);
    expect$.Expect.equals(6.333333333333333, compile_time_constant2_test.g3);
    expect$.Expect.equals(6, compile_time_constant2_test.g4);
    expect$.Expect.equals(152, compile_time_constant2_test.g5);
    expect$.Expect.equals(2, compile_time_constant2_test.g6);
    expect$.Expect.equals(4, compile_time_constant2_test.g7);
    expect$.Expect.equals(-19, compile_time_constant2_test.g8);
    expect$.Expect.equals(false, compile_time_constant2_test.g9);
    expect$.Expect.equals(false, compile_time_constant2_test.g10);
    expect$.Expect.equals(true, compile_time_constant2_test.g11);
    expect$.Expect.equals(true, compile_time_constant2_test.g12);
    expect$.Expect.equals(true, compile_time_constant2_test.g13);
    expect$.Expect.equals(true, compile_time_constant2_test.g14);
    expect$.Expect.equals(false, compile_time_constant2_test.g15);
    expect$.Expect.equals(true, compile_time_constant2_test.g16);
    expect$.Expect.equals(true, compile_time_constant2_test.g17);
    expect$.Expect.equals(false, compile_time_constant2_test.g18);
    expect$.Expect.equals(19, compile_time_constant2_test.g19);
    expect$.Expect.equals(3, compile_time_constant2_test.g20);
    expect$.Expect.equals(16, compile_time_constant2_test.g21);
    expect$.Expect.equals(224, compile_time_constant2_test.g22);
    expect$.Expect.equals(1, compile_time_constant2_test.g23);
  };
  dart.fn(compile_time_constant2_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant2_test = compile_time_constant2_test;
});
