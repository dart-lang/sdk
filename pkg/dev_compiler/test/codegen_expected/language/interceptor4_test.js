dart_library.library('language/interceptor4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__interceptor4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const interceptor4_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  interceptor4_test.main = function() {
    let a = JSArrayOfint().of([1]);
    let b = a[dartx.get](0);
    expect$.Expect.equals('1', dart.toString(b));
    expect$.Expect.isTrue(b[dartx.isOdd]);
  };
  dart.fn(interceptor4_test.main, VoidTodynamic());
  // Exports:
  exports.interceptor4_test = interceptor4_test;
});
