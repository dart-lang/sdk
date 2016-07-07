dart_library.library('language/closure5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure5_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure5_test.foo = function(f) {
    return dart.dcall(f, 499);
  };
  dart.fn(closure5_test.foo, dynamicTodynamic());
  closure5_test.main = function() {
    function fun(x) {
      if (dart.test(dart.dsend(x, '<', 3))) {
        return closure5_test.foo(dart.fn(x => fun(x), dynamicTodynamic()));
      } else {
        return x;
      }
    }
    dart.fn(fun, dynamicTodynamic());
    expect$.Expect.equals(499, closure5_test.foo(dart.fn(x => fun(x), dynamicTodynamic())));
  };
  dart.fn(closure5_test.main, VoidTodynamic());
  // Exports:
  exports.closure5_test = closure5_test;
});
