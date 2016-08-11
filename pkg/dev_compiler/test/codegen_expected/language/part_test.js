dart_library.library('language/part_test', null, /* Imports */[
  'dart_sdk'
], function load__part_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const part_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  part_test.main = function() {
    core.print(part_test.foo);
  };
  dart.fn(part_test.main, VoidTodynamic());
  part_test.foo = 'foo';
  // Exports:
  exports.part_test = part_test;
});
