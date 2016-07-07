dart_library.library('language/compile_time_constant11_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant11_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant11_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant11_test.C1 = true;
  compile_time_constant11_test.C2 = false;
  compile_time_constant11_test.nephew = compile_time_constant11_test.C1 ? compile_time_constant11_test.C2 ? "Tick" : "Trick" : "Track";
  let const$;
  compile_time_constant11_test.main = function() {
    let a = true ? 5 : 10;
    let b = compile_time_constant11_test.C2 ? "Track" : compile_time_constant11_test.C1 ? "Trick" : "Tick";
    expect$.Expect.equals(5, a);
    expect$.Expect.equals("Trick", compile_time_constant11_test.nephew);
    expect$.Expect.equals(compile_time_constant11_test.nephew, b);
    expect$.Expect.identical(compile_time_constant11_test.nephew, b);
    let s = const$ || (const$ = dart.const(core.Symbol.new(compile_time_constant11_test.nephew)));
    let msg = dart.str`Donald is ${compile_time_constant11_test.nephew}'s uncle.`;
    expect$.Expect.equals("Donald is Trick's uncle.", msg);
  };
  dart.fn(compile_time_constant11_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant11_test = compile_time_constant11_test;
});
