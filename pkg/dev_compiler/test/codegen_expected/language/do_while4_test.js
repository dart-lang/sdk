dart_library.library('language/do_while4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__do_while4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const do_while4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  do_while4_test.a = false;
  do_while4_test.main = function() {
    do {
      if (!dart.test(do_while4_test.a)) break;
      let c = do_while4_test.main();
      do_while4_test.a = true;
    } while (true);
    expect$.Expect.isFalse(do_while4_test.a);
  };
  dart.fn(do_while4_test.main, VoidTodynamic());
  // Exports:
  exports.do_while4_test = do_while4_test;
});
