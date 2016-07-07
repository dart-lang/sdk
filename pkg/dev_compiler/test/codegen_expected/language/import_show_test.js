dart_library.library('language/import_show_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__import_show_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const import_show_test = Object.create(null);
  const import_show_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  import_show_test.main = function() {
    let foo = import_show_lib.theEnd;
    expect$.Expect.equals("http://www.endoftheinternet.com/", foo);
  };
  dart.fn(import_show_test.main, VoidTodynamic());
  dart.copyProperties(import_show_lib, {
    get theEnd() {
      return "http://www.endoftheinternet.com/";
    }
  });
  // Exports:
  exports.import_show_test = import_show_test;
  exports.import_show_lib = import_show_lib;
});
