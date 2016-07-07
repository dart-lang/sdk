dart_library.library('language/compile_time_constant_arguments_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__compile_time_constant_arguments_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const compile_time_constant_arguments_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_arguments_test_none_multi.A = class A extends core.Object {
    new(a) {
    }
    named(opts) {
      let a = opts && 'a' in opts ? opts.a : 42;
    }
    optional(a) {
      if (a === void 0) a = null;
    }
  };
  dart.defineNamedConstructor(compile_time_constant_arguments_test_none_multi.A, 'named');
  dart.defineNamedConstructor(compile_time_constant_arguments_test_none_multi.A, 'optional');
  dart.setSignature(compile_time_constant_arguments_test_none_multi.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(compile_time_constant_arguments_test_none_multi.A, [dart.dynamic]),
      named: dart.definiteFunctionType(compile_time_constant_arguments_test_none_multi.A, [], {a: dart.dynamic}),
      optional: dart.definiteFunctionType(compile_time_constant_arguments_test_none_multi.A, [], [dart.dynamic])
    })
  });
  let const$;
  let const$0;
  let const$1;
  let const$2;
  compile_time_constant_arguments_test_none_multi.main = function() {
    const$ || (const$ = dart.const(new compile_time_constant_arguments_test_none_multi.A(1)));
    const$0 || (const$0 = dart.const(new compile_time_constant_arguments_test_none_multi.A.named()));
    const$1 || (const$1 = dart.const(new compile_time_constant_arguments_test_none_multi.A.optional()));
    const$2 || (const$2 = dart.const(new compile_time_constant_arguments_test_none_multi.A.optional(42)));
  };
  dart.fn(compile_time_constant_arguments_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_arguments_test_none_multi = compile_time_constant_arguments_test_none_multi;
});
