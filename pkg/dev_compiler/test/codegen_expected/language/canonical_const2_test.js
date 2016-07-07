dart_library.library('language/canonical_const2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__canonical_const2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const canonical_const2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  canonical_const2_test.main = function() {
    expect$.Expect.isFalse(core.identical(const$ || (const$ = dart.constList([1, 2], core.num)), const$0 || (const$0 = dart.constList([1.0, 2.0], core.num))));
  };
  dart.fn(canonical_const2_test.main, VoidTodynamic());
  // Exports:
  exports.canonical_const2_test = canonical_const2_test;
});
