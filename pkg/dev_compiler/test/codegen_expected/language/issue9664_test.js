dart_library.library('language/issue9664_test', null, /* Imports */[
  'dart_sdk'
], function load__issue9664_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue9664_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue9664_test.main = function() {
    while (true ? true : true)
      break;
  };
  dart.fn(issue9664_test.main, VoidTodynamic());
  // Exports:
  exports.issue9664_test = issue9664_test;
});
