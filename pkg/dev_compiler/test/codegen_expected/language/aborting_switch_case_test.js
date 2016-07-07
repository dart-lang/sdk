dart_library.library('language/aborting_switch_case_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__aborting_switch_case_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const aborting_switch_case_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  aborting_switch_case_test.foo = function() {
    dart.throw(42);
  };
  dart.fn(aborting_switch_case_test.foo, VoidTodynamic());
  aborting_switch_case_test.main = function() {
    let exception = null;
    try {
      switch (42) {
        case 42:
        {
          aborting_switch_case_test.foo();
          aborting_switch_case_test.foo();
          break;
        }
      }
    } catch (e) {
      exception = e;
    }

    expect$.Expect.equals(42, exception);
  };
  dart.fn(aborting_switch_case_test.main, VoidTodynamic());
  // Exports:
  exports.aborting_switch_case_test = aborting_switch_case_test;
});
