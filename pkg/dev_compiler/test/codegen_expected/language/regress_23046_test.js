dart_library.library('language/regress_23046_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_23046_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_23046_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_23046_test.y = 'foo';
  regress_23046_test.x = dart.str`${regress_23046_test.y}"`;
  regress_23046_test.m = dart.const(dart.map([regress_23046_test.x, 0, regress_23046_test.y, 1]));
  regress_23046_test.main = function() {
    expect$.Expect.equals(regress_23046_test.x, 'foo"');
    expect$.Expect.equals(regress_23046_test.m[dartx.length], 2);
  };
  dart.fn(regress_23046_test.main, VoidTodynamic());
  // Exports:
  exports.regress_23046_test = regress_23046_test;
});
