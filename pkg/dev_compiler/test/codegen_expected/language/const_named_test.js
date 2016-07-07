dart_library.library('language/const_named_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_named_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_named_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  const_named_test.main = function() {
    let d = const$ || (const$ = dart.const(new core.Duration({milliseconds: 499})));
    expect$.Expect.equals(499, d.inMilliseconds);
  };
  dart.fn(const_named_test.main, VoidTodynamic());
  // Exports:
  exports.const_named_test = const_named_test;
});
