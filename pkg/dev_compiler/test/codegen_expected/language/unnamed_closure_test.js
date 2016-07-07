dart_library.library('language/unnamed_closure_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__unnamed_closure_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const unnamed_closure_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  unnamed_closure_test.getNonArray = function() {
    return new unnamed_closure_test.A();
  };
  dart.fn(unnamed_closure_test.getNonArray, VoidTodynamic());
  unnamed_closure_test.A = class A extends core.Object {
    get(index) {
      return index;
    }
  };
  dart.setSignature(unnamed_closure_test.A, {
    methods: () => ({get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  unnamed_closure_test.main = function() {
    expect$.Expect.equals(42, dart.fn(() => {
      let res = null;
      do {
        let a = unnamed_closure_test.getNonArray();
        res = dart.dindex(a, 42);
      } while (false);
      return res;
    }, VoidTodynamic())());
  };
  dart.fn(unnamed_closure_test.main, VoidTodynamic());
  // Exports:
  exports.unnamed_closure_test = unnamed_closure_test;
});
