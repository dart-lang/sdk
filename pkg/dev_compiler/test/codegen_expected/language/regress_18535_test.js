dart_library.library('language/regress_18535_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_18535_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_18535_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  regress_18535_test.main = function() {
    core.print(mirrors.currentMirrorSystem().libraries);
  };
  dart.fn(regress_18535_test.main, VoidTovoid());
  // Exports:
  exports.regress_18535_test = regress_18535_test;
});
