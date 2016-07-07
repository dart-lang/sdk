dart_library.library('language/patch_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__patch_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const patch_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  patch_test.patch = function() {
    return 12;
  };
  dart.fn(patch_test.patch, VoidTodynamic());
  patch_test.main = function() {
    let x = patch_test.patch();
    expect$.Expect.equals(12, x);
  };
  dart.fn(patch_test.main, VoidTodynamic());
  // Exports:
  exports.patch_test = patch_test;
});
