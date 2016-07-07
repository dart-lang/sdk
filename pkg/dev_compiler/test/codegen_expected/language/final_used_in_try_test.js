dart_library.library('language/final_used_in_try_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__final_used_in_try_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const final_used_in_try_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  final_used_in_try_test.main = function() {
    while (true) {
      let a = 'fff'[dartx.substring](1, 2);
      try {
        expect$.Expect.equals('f', a);
      } catch (e) {
        throw e;
      }

      break;
    }
  };
  dart.fn(final_used_in_try_test.main, VoidTodynamic());
  // Exports:
  exports.final_used_in_try_test = final_used_in_try_test;
});
