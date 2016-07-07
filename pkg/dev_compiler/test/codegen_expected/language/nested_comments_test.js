dart_library.library('language/nested_comments_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__nested_comments_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const nested_comments_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  nested_comments_test.main = function() {
    expect$.Expect.isTrue(true);
  };
  dart.fn(nested_comments_test.main, VoidTodynamic());
  // Exports:
  exports.nested_comments_test = nested_comments_test;
});
