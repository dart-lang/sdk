dart_library.library('language/null_to_string_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null_to_string_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null_to_string_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  null_to_string_test.main = function() {
    let nullObj = null;
    let x = dart.toString(nullObj);
    expect$.Expect.isTrue(typeof x == 'string');
    let y = dart.toString(nullObj);
    expect$.Expect.isNotNull(y);
  };
  dart.fn(null_to_string_test.main, VoidTodynamic());
  // Exports:
  exports.null_to_string_test = null_to_string_test;
});
