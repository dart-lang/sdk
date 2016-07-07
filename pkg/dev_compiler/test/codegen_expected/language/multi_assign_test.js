dart_library.library('language/multi_assign_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__multi_assign_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const multi_assign_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  multi_assign_test.MultiAssignTest = class MultiAssignTest extends core.Object {
    static testMain() {
      let i = null, j = null, k = null;
      i = j = k = 11;
      expect$.Expect.equals(11, i);
      expect$.Expect.equals(11, j);
      expect$.Expect.equals(11, k);
      let m = null;
      let n = m = k = 55;
      expect$.Expect.equals(55, m);
      expect$.Expect.equals(55, n);
      expect$.Expect.equals(55, k);
    }
  };
  dart.setSignature(multi_assign_test.MultiAssignTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  multi_assign_test.main = function() {
    multi_assign_test.MultiAssignTest.testMain();
  };
  dart.fn(multi_assign_test.main, VoidTodynamic());
  // Exports:
  exports.multi_assign_test = multi_assign_test;
});
