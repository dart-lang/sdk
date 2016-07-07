dart_library.library('language/do_while3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__do_while3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const do_while3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  do_while3_test.main = function() {
    let c = 0;
    do {
      c++;
    } while (c++ < 2);
    expect$.Expect.equals(4, c);
  };
  dart.fn(do_while3_test.main, VoidTodynamic());
  // Exports:
  exports.do_while3_test = do_while3_test;
});
