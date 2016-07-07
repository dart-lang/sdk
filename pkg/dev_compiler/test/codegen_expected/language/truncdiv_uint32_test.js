dart_library.library('language/truncdiv_uint32_test', null, /* Imports */[
  'dart_sdk'
], function load__truncdiv_uint32_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const truncdiv_uint32_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(truncdiv_uint32_test, {
    get a() {
      return JSArrayOfint().of([4294967295]);
    },
    set a(_) {}
  });
  truncdiv_uint32_test.main = function() {
    if ((dart.notNull(truncdiv_uint32_test.a[dartx.get](0)) / 1)[dartx.truncate]() != 4294967295) dart.throw('Test failed');
  };
  dart.fn(truncdiv_uint32_test.main, VoidTodynamic());
  // Exports:
  exports.truncdiv_uint32_test = truncdiv_uint32_test;
});
