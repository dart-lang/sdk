dart_library.library('language/inferrer_closure_test', null, /* Imports */[
  'dart_sdk'
], function load__inferrer_closure_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const inferrer_closure_test = Object.create(null);
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(inferrer_closure_test, {
    get closure() {
      return dart.fn(a => dart.toString(a), dynamicToString());
    },
    set closure(_) {}
  });
  dart.copyProperties(inferrer_closure_test, {
    get foo() {
      return inferrer_closure_test.closure;
    }
  });
  inferrer_closure_test.main = function() {
    if (!dart.equals(dart.dcall(inferrer_closure_test.foo, 42), '42')) {
      dart.throw('Test failed');
    }
  };
  dart.fn(inferrer_closure_test.main, VoidTodynamic());
  // Exports:
  exports.inferrer_closure_test = inferrer_closure_test;
});
