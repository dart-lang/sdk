dart_library.library('corelib/main_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__main_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const main_test = Object.create(null);
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let ListOfStringTodynamic = () => (ListOfStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [ListOfString()])))();
  main_test.main = function(args) {
    expect$.Expect.equals(0, args[dartx.length]);
  };
  dart.fn(main_test.main, ListOfStringTodynamic());
  // Exports:
  exports.main_test = main_test;
});
