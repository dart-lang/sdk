dart_library.library('language/setter_no_getter_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setter_no_getter_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setter_no_getter_test_01_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.copyProperties(setter_no_getter_test_01_multi, {
    set topLevel(value) {}
  });
  setter_no_getter_test_01_multi.main = function() {
    expect$.Expect.equals(42, (() => {
      let x = setter_no_getter_test_01_multi.topLevel;
      setter_no_getter_test_01_multi.topLevel = dart.dsend(x, '+', 1);
      return x;
    })());
  };
  dart.fn(setter_no_getter_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.setter_no_getter_test_01_multi = setter_no_getter_test_01_multi;
});
