dart_library.library('language/library_juxtaposition_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__library_juxtaposition_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const library_juxtaposition_test = Object.create(null);
  const library_juxtaposition_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  library_juxtaposition_test.main = function() {
    expect$.Expect.equals(library_juxtaposition_lib.c, 47);
  };
  dart.fn(library_juxtaposition_test.main, VoidTodynamic());
  library_juxtaposition_lib.c = 47;
  library_juxtaposition_test.c = library_juxtaposition_lib.c;
  // Exports:
  exports.library_juxtaposition_test = library_juxtaposition_test;
  exports.library_juxtaposition_lib = library_juxtaposition_lib;
});
