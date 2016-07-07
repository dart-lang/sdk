dart_library.library('language/interceptor5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__interceptor5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const interceptor5_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.functionType(core.int, [])))();
  let JSArrayOfVoidToint = () => (JSArrayOfVoidToint = dart.constFn(_interceptors.JSArray$(VoidToint())))();
  let VoidToint$ = () => (VoidToint$ = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.copyProperties(interceptor5_test, {
    get X() {
      return JSArrayOfVoidToint().of([dart.fn(() => 123, VoidToint$())]);
    }
  });
  interceptor5_test.main = function() {
    expect$.Expect.equals(123, dart.dsend(interceptor5_test.X, 'last'));
  };
  dart.fn(interceptor5_test.main, VoidTodynamic());
  // Exports:
  exports.interceptor5_test = interceptor5_test;
});
