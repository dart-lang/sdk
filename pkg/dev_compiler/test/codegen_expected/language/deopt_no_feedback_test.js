dart_library.library('language/deopt_no_feedback_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deopt_no_feedback_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deopt_no_feedback_test = Object.create(null);
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  deopt_no_feedback_test.testStoreIndexed = function() {
    function test(a, i, v, flag) {
      if (dart.test(flag)) {
        return dart.dsetindex(a, i, v);
      } else {
        return dart.dsetindex(a, i, i);
      }
    }
    dart.fn(test, dynamicAnddynamicAnddynamic__Todynamic());
    let a = core.List.new(10);
    for (let i = 0; i < 20; i++) {
      let r = test(a, 3, 888, false);
      expect$.Expect.equals(3, r);
      expect$.Expect.equals(3, a[dartx.get](3));
    }
    let r = test(a, 3, 888, true);
    expect$.Expect.equals(888, r);
    expect$.Expect.equals(888, a[dartx.get](3));
  };
  dart.fn(deopt_no_feedback_test.testStoreIndexed, VoidTodynamic());
  deopt_no_feedback_test.testIncrLocal = function() {
    function test(a, flag) {
      if (dart.test(flag)) {
        a = dart.dsend(a, '+', 1);
        return a;
      } else {
        return -1;
      }
    }
    dart.fn(test, dynamicAnddynamicTodynamic());
    for (let i = 0; i < 20; i++) {
      let r = test(10, false);
      expect$.Expect.equals(-1, r);
    }
    let r = test(10, true);
    expect$.Expect.equals(11, r);
  };
  dart.fn(deopt_no_feedback_test.testIncrLocal, VoidTodynamic());
  deopt_no_feedback_test.main = function() {
    for (let i = 0; i < 20; i++) {
    }
    deopt_no_feedback_test.testStoreIndexed();
    deopt_no_feedback_test.testIncrLocal();
  };
  dart.fn(deopt_no_feedback_test.main, VoidTodynamic());
  // Exports:
  exports.deopt_no_feedback_test = deopt_no_feedback_test;
});
