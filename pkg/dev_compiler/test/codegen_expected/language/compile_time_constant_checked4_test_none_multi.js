dart_library.library('language/compile_time_constant_checked4_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__compile_time_constant_checked4_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const compile_time_constant_checked4_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _x = Symbol('_x');
  compile_time_constant_checked4_test_none_multi.A = class A extends core.Object {
    a1(x) {
      A.prototype.a2.call(this, x);
    }
    a2(x) {
      A.prototype.a3.call(this, x);
    }
    a3(x) {
      this[_x] = x;
    }
  };
  dart.defineNamedConstructor(compile_time_constant_checked4_test_none_multi.A, 'a1');
  dart.defineNamedConstructor(compile_time_constant_checked4_test_none_multi.A, 'a2');
  dart.defineNamedConstructor(compile_time_constant_checked4_test_none_multi.A, 'a3');
  dart.setSignature(compile_time_constant_checked4_test_none_multi.A, {
    constructors: () => ({
      a1: dart.definiteFunctionType(compile_time_constant_checked4_test_none_multi.A, [dart.dynamic]),
      a2: dart.definiteFunctionType(compile_time_constant_checked4_test_none_multi.A, [dart.dynamic]),
      a3: dart.definiteFunctionType(compile_time_constant_checked4_test_none_multi.A, [dart.dynamic])
    })
  });
  compile_time_constant_checked4_test_none_multi.use = function(x) {
    return x;
  };
  dart.fn(compile_time_constant_checked4_test_none_multi.use, dynamicTodynamic());
  let const$;
  compile_time_constant_checked4_test_none_multi.main = function() {
    compile_time_constant_checked4_test_none_multi.use(const$ || (const$ = dart.const(new compile_time_constant_checked4_test_none_multi.A.a1(0))));
  };
  dart.fn(compile_time_constant_checked4_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_checked4_test_none_multi = compile_time_constant_checked4_test_none_multi;
});
