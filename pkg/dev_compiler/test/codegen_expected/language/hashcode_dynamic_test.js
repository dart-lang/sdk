dart_library.library('language/hashcode_dynamic_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__hashcode_dynamic_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const hashcode_dynamic_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  hashcode_dynamic_test.main = function() {
    let x = 3;
    expect$.Expect.equals(3, dart.hashCode(x));
  };
  dart.fn(hashcode_dynamic_test.main, VoidTovoid());
  // Exports:
  exports.hashcode_dynamic_test = hashcode_dynamic_test;
});
