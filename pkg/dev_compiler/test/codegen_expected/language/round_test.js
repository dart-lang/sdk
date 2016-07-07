dart_library.library('language/round_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__round_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const round_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  round_test.main = function() {
    expect$.Expect.equals(0, 0.49999999999999994[dartx.round]());
    expect$.Expect.equals(0, (-0.49999999999999994)[dartx.round]());
    expect$.Expect.equals(9007199254740991, 9007199254740991.0[dartx.round]());
    expect$.Expect.equals(-9007199254740991, (-9007199254740991.0)[dartx.round]());
  };
  dart.fn(round_test.main, VoidTodynamic());
  // Exports:
  exports.round_test = round_test;
});
