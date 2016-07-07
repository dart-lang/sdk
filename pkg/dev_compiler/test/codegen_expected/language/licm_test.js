dart_library.library('language/licm_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__licm_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const licm_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  licm_test.sum = 0;
  licm_test.foo = 0;
  licm_test.bar = 1;
  licm_test.test = function() {
    while (true) {
      if (0 == licm_test.foo) {
        licm_test.sum = dart.notNull(licm_test.sum) + 2;
        if (1 == licm_test.bar) {
          licm_test.sum = dart.notNull(licm_test.sum) + 3;
          break;
        }
        break;
      }
    }
  };
  dart.fn(licm_test.test, VoidTodynamic());
  licm_test.main = function() {
    licm_test.test();
    expect$.Expect.equals(5, licm_test.sum);
  };
  dart.fn(licm_test.main, VoidTodynamic());
  // Exports:
  exports.licm_test = licm_test;
});
