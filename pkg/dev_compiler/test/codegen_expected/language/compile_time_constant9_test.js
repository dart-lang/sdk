dart_library.library('language/compile_time_constant9_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant9_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant9_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant9_test.B = class B extends core.Object {
    new() {
    }
  };
  dart.setSignature(compile_time_constant9_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant9_test.B, [])})
  });
  let const$;
  compile_time_constant9_test.A = class A extends core.Object {
    new() {
      this.x = const$ || (const$ = dart.const(new compile_time_constant9_test.B()));
    }
  };
  dart.setSignature(compile_time_constant9_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant9_test.A, [])})
  });
  compile_time_constant9_test.main = function() {
    expect$.Expect.isTrue(core.identical(new compile_time_constant9_test.A().x, new compile_time_constant9_test.A().x));
  };
  dart.fn(compile_time_constant9_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant9_test = compile_time_constant9_test;
});
