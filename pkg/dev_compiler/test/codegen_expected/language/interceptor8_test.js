dart_library.library('language/interceptor8_test', null, /* Imports */[
  'dart_sdk'
], function load__interceptor8_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const interceptor8_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(interceptor8_test, {
    get a() {
      return JSArrayOfint().of([5, 2]);
    },
    set a(_) {}
  });
  interceptor8_test.main = function() {
    core.print(dart.notNull(interceptor8_test.a[dartx.get](0)) / dart.notNull(interceptor8_test.a[dartx.get](1)));
  };
  dart.fn(interceptor8_test.main, VoidTodynamic());
  // Exports:
  exports.interceptor8_test = interceptor8_test;
});
