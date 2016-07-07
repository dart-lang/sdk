dart_library.library('language/compile_time_constant3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant3_test.x = 19.5;
  compile_time_constant3_test.y = 3.3;
  compile_time_constant3_test.g1 = compile_time_constant3_test.x + compile_time_constant3_test.y;
  compile_time_constant3_test.g2 = compile_time_constant3_test.x * compile_time_constant3_test.y;
  compile_time_constant3_test.g3 = compile_time_constant3_test.x / compile_time_constant3_test.y;
  compile_time_constant3_test.g4 = (compile_time_constant3_test.x / compile_time_constant3_test.y)[dartx.truncate]();
  compile_time_constant3_test.g5 = -compile_time_constant3_test.x;
  compile_time_constant3_test.g6 = compile_time_constant3_test.x < compile_time_constant3_test.y;
  compile_time_constant3_test.g7 = compile_time_constant3_test.x <= compile_time_constant3_test.y;
  compile_time_constant3_test.g8 = compile_time_constant3_test.x <= compile_time_constant3_test.x;
  compile_time_constant3_test.g9 = compile_time_constant3_test.x > compile_time_constant3_test.y;
  compile_time_constant3_test.g10 = compile_time_constant3_test.x >= compile_time_constant3_test.y;
  compile_time_constant3_test.g11 = compile_time_constant3_test.x >= compile_time_constant3_test.x;
  compile_time_constant3_test.g12 = compile_time_constant3_test.x == compile_time_constant3_test.y;
  compile_time_constant3_test.g13 = compile_time_constant3_test.x == compile_time_constant3_test.x;
  compile_time_constant3_test.g14 = compile_time_constant3_test.x != compile_time_constant3_test.y;
  compile_time_constant3_test.g15 = compile_time_constant3_test.x != compile_time_constant3_test.x;
  compile_time_constant3_test.g16 = compile_time_constant3_test.g1 + compile_time_constant3_test.g2 + compile_time_constant3_test.g3 + compile_time_constant3_test.g4 + compile_time_constant3_test.g5;
  compile_time_constant3_test.g17 = compile_time_constant3_test.x[dartx['%']](compile_time_constant3_test.y);
  compile_time_constant3_test.main = function() {
    expect$.Expect.equals(22.8, compile_time_constant3_test.g1);
    expect$.Expect.equals(64.35, compile_time_constant3_test.g2);
    expect$.Expect.equals(5.909090909090909, compile_time_constant3_test.g3);
    expect$.Expect.equals(5.0, compile_time_constant3_test.g4);
    expect$.Expect.equals(-19.5, compile_time_constant3_test.g5);
    expect$.Expect.equals(false, compile_time_constant3_test.g6);
    expect$.Expect.equals(false, compile_time_constant3_test.g7);
    expect$.Expect.equals(true, compile_time_constant3_test.g8);
    expect$.Expect.equals(true, compile_time_constant3_test.g9);
    expect$.Expect.equals(true, compile_time_constant3_test.g10);
    expect$.Expect.equals(true, compile_time_constant3_test.g11);
    expect$.Expect.equals(false, compile_time_constant3_test.g12);
    expect$.Expect.equals(true, compile_time_constant3_test.g13);
    expect$.Expect.equals(true, compile_time_constant3_test.g14);
    expect$.Expect.equals(false, compile_time_constant3_test.g15);
    expect$.Expect.equals(78.5590909090909, compile_time_constant3_test.g16);
    expect$.Expect.equals(3.000000000000001, compile_time_constant3_test.g17);
  };
  dart.fn(compile_time_constant3_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant3_test = compile_time_constant3_test;
});
