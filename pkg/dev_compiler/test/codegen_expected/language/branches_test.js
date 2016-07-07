dart_library.library('language/branches_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__branches_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const branches_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  branches_test.BranchesTest = class BranchesTest extends core.Object {
    static f() {
      expect$.Expect.equals("Never reached", 0);
      return true;
    }
    static testMain() {
      let checkPointCounter = 1;
      let checkPoint1 = 0;
      let checkPoint2 = 0;
      let checkPoint3 = 0;
      let checkPoint4 = 0;
      let checkPoint5 = 0;
      let checkPoint6 = 0;
      let i = 0;
      for (let i = 0; i < 2; i++) {
        if (i == 0) {
          checkPoint1 = checkPoint1 + checkPointCounter++;
          if (true || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f()) || dart.test(branches_test.BranchesTest.f())) {
            checkPoint2 = checkPoint2 + checkPointCounter++;
          }
        } else {
          checkPoint3 = checkPoint3 + checkPointCounter++;
          if (false) {
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
            checkPoint4 = checkPointCounter++;
          }
        }
        checkPoint5 = checkPoint5 + checkPointCounter++;
      }
      checkPoint6 = checkPoint6 + checkPointCounter++;
      expect$.Expect.equals(1, checkPoint1);
      expect$.Expect.equals(2, checkPoint2);
      expect$.Expect.equals(4, checkPoint3);
      expect$.Expect.equals(0, checkPoint4);
      expect$.Expect.equals(8, checkPoint5);
      expect$.Expect.equals(6, checkPoint6);
    }
  };
  dart.setSignature(branches_test.BranchesTest, {
    statics: () => ({
      f: dart.definiteFunctionType(core.bool, []),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['f', 'testMain']
  });
  branches_test.main = function() {
    branches_test.BranchesTest.testMain();
  };
  dart.fn(branches_test.main, VoidTodynamic());
  // Exports:
  exports.branches_test = branches_test;
});
