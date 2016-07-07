dart_library.library('language/issue_22780_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__issue_22780_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue_22780_test_01_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue_22780_test_01_multi.main = function() {
    function f() {
      return dart.str`Oh, the joy of ${f()}`;
    }
    dart.fn(f, VoidTodynamic());
    core.print(f());
  };
  dart.fn(issue_22780_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.issue_22780_test_01_multi = issue_22780_test_01_multi;
});
