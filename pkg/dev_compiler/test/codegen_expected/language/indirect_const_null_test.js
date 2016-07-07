dart_library.library('language/indirect_const_null_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__indirect_const_null_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const indirect_const_null_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  indirect_const_null_test.main = function() {
    let NULL = 1 == 1 ? null : false;
    expect$.Expect.isNull(NULL);
  };
  dart.fn(indirect_const_null_test.main, VoidTodynamic());
  // Exports:
  exports.indirect_const_null_test = indirect_const_null_test;
});
