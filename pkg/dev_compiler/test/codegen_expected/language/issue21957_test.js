dart_library.library('language/issue21957_test', null, /* Imports */[
  'dart_sdk'
], function load__issue21957_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue21957_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue21957_test.main = function() {
    for (let i = 0; i < 1000000; i++) {
      new issue21957_test.A();
    }
  };
  dart.fn(issue21957_test.main, VoidTodynamic());
  issue21957_test.A = class A extends core.Object {
    new() {
      this.a = 1.0;
    }
  };
  // Exports:
  exports.issue21957_test = issue21957_test;
});
