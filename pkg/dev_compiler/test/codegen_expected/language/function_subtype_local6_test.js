dart_library.library('language/function_subtype_local6_test', null, /* Imports */[
  'dart_sdk'
], function load__function_subtype_local6_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const function_subtype_local6_test = Object.create(null);
  let C = () => (C = dart.constFn(function_subtype_local6_test.C$()))();
  let COfbool = () => (COfbool = dart.constFn(function_subtype_local6_test.C$(core.bool)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_local6_test.C$ = dart.generic(T => {
    let TTovoid = () => (TTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [T])))();
    class C extends core.Object {
      test() {
        function foo(a) {
        }
        dart.fn(foo, TTovoid());
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({test: dart.definiteFunctionType(dart.void, [])})
    });
    return C;
  });
  function_subtype_local6_test.C = C();
  function_subtype_local6_test.main = function() {
    new (COfbool())().test();
  };
  dart.fn(function_subtype_local6_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_local6_test = function_subtype_local6_test;
});
