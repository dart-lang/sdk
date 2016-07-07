dart_library.library('language/closure4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure4_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure4_test.foo = function(f) {
    return dart.dcall(f, 499);
  };
  dart.fn(closure4_test.foo, dynamicTodynamic());
  closure4_test.main = function() {
    function fun(x) {
      if (dart.test(dart.dsend(x, '<', 3))) {
        return closure4_test.foo(dart.fn(x => fun(x), dynamicTodynamic()));
      } else {
        return x;
      }
    }
    dart.fn(fun, dynamicTodynamic());
    expect$.Expect.equals(499, fun(499));
  };
  dart.fn(closure4_test.main, VoidTodynamic());
  // Exports:
  exports.closure4_test = closure4_test;
});
