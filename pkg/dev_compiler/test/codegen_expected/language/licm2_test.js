dart_library.library('language/licm2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__licm2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const licm2_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  licm2_test.a = 42;
  licm2_test.b = null;
  licm2_test.main = function() {
    expect$.Expect.throws(dart.fn(() => {
      while (true) {
        licm2_test.a = 54;
        dart.dload(licm2_test.b, 'length');
      }
    }, VoidTovoid()));
    licm2_test.b = [];
    expect$.Expect.equals(54, licm2_test.a);
  };
  dart.fn(licm2_test.main, VoidTodynamic());
  // Exports:
  exports.licm2_test = licm2_test;
});
