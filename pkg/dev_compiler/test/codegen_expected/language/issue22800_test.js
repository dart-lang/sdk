dart_library.library('language/issue22800_test', null, /* Imports */[
  'dart_sdk'
], function load__issue22800_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue22800_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  issue22800_test.main = function() {
    try {
      core.print("Starting here");
      dart.throw(0);
      try {
      } catch (e) {
      }

    } catch (e) {
      core.print(dart.str`Caught in here: ${e}`);
    }

    try {
    } catch (e) {
    }

  };
  dart.fn(issue22800_test.main, VoidTovoid());
  // Exports:
  exports.issue22800_test = issue22800_test;
});
