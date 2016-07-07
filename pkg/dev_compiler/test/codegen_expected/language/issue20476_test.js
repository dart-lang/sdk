dart_library.library('language/issue20476_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue20476_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue20476_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue20476_test.foo = function() {
    try {
      try {
        return 1;
      } catch (e1) {
      }
 finally {
        return 3;
      }
    } catch (e2) {
    }
 finally {
      return 5;
    }
  };
  dart.fn(issue20476_test.foo, VoidTodynamic());
  issue20476_test.main = function() {
    expect$.Expect.equals(5, issue20476_test.foo());
  };
  dart.fn(issue20476_test.main, VoidTodynamic());
  // Exports:
  exports.issue20476_test = issue20476_test;
});
