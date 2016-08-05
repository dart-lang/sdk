dart_library.library('language/bool_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bool_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bool_test = Object.create(null);
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  bool_test.BoolTest = class BoolTest extends core.Object {
    static testEquality() {
      expect$.Expect.equals(true, true);
      expect$.Expect.equals(false, false);
      expect$.Expect.isTrue(core.identical(true, true));
      expect$.Expect.isFalse(core.identical(true, false));
      expect$.Expect.isTrue(core.identical(false, false));
      expect$.Expect.isFalse(core.identical(false, true));
      expect$.Expect.isFalse(!core.identical(true, true));
      expect$.Expect.isTrue(!core.identical(true, false));
      expect$.Expect.isFalse(!core.identical(false, false));
      expect$.Expect.isTrue(!core.identical(false, true));
      expect$.Expect.isTrue(true == true);
      expect$.Expect.isFalse(true == false);
      expect$.Expect.isTrue(false == false);
      expect$.Expect.isFalse(false == true);
      expect$.Expect.isFalse(true != true);
      expect$.Expect.isTrue(true != false);
      expect$.Expect.isFalse(false != false);
      expect$.Expect.isTrue(false != true);
      expect$.Expect.isTrue(core.identical(true, true == true));
      expect$.Expect.isTrue(core.identical(false, true == false));
      expect$.Expect.isTrue(core.identical(true, false == false));
      expect$.Expect.isTrue(core.identical(false, false == true));
      expect$.Expect.isFalse(!core.identical(true, true == true));
      expect$.Expect.isFalse(!core.identical(false, true == false));
      expect$.Expect.isFalse(!core.identical(true, false == false));
      expect$.Expect.isFalse(!core.identical(false, false == true));
      expect$.Expect.isFalse(core.identical(false, true == true));
      expect$.Expect.isFalse(core.identical(true, true == false));
      expect$.Expect.isFalse(core.identical(false, false == false));
      expect$.Expect.isFalse(core.identical(true, false == true));
      expect$.Expect.isTrue(!core.identical(false, true == true));
      expect$.Expect.isTrue(!core.identical(true, true == false));
      expect$.Expect.isTrue(!core.identical(false, false == false));
      expect$.Expect.isTrue(!core.identical(true, false == true));
      if (true == false) {
        dart.throw("Expect.equals broken");
      }
      if (false == true) {
        dart.throw("Expect.equals broken");
      }
      if (core.identical(true, false)) {
        dart.throw("Expect.equals broken");
      }
      if (core.identical(false, true)) {
        dart.throw("Expect.equals broken");
      }
      if (true == true) {
      } else {
        dart.throw("Expect.equals broken");
      }
      if (false == false) {
      } else {
        dart.throw("Expect.equals broken");
      }
      if (core.identical(true, true)) {
      } else {
        dart.throw("Expect.equals broken");
      }
      if (core.identical(false, false)) {
      } else {
        dart.throw("Expect.equals broken");
      }
      if (true != false) {
      } else {
        dart.throw("Expect.equals broken");
      }
      if (false != true) {
      } else {
        dart.throw("Expect.equals broken");
      }
      if (!core.identical(true, false)) {
      } else {
        dart.throw("Expect.equals broken");
      }
      if (!core.identical(false, true)) {
      } else {
        dart.throw("Expect.equals broken");
      }
      if (true != true) {
        dart.throw("Expect.equals broken");
      }
      if (false != false) {
        dart.throw("Expect.equals broken");
      }
      if (!core.identical(true, true)) {
        dart.throw("Expect.equals broken");
      }
      if (!core.identical(false, false)) {
        dart.throw("Expect.equals broken");
      }
    }
    static testToString() {
      expect$.Expect.equals("true", dart.toString(true));
      expect$.Expect.equals("false", dart.toString(false));
    }
    static testNegate(isTrue, isFalse) {
      expect$.Expect.equals(true, !false);
      expect$.Expect.equals(false, !true);
      expect$.Expect.equals(true, !dart.test(isFalse));
      expect$.Expect.equals(false, !dart.test(isTrue));
    }
    static testLogicalOp() {
      function testOr(a, b, onTypeError) {
        try {
          return dart.test(a) || dart.test(b);
        } catch (t) {
          if (core.TypeError.is(t)) {
            return onTypeError;
          } else
            throw t;
        }

      }
      dart.fn(testOr, dynamicAnddynamicAnddynamicTodynamic());
      function testAnd(a, b, onTypeError) {
        try {
          return dart.test(a) && dart.test(b);
        } catch (t) {
          if (core.TypeError.is(t)) {
            return onTypeError;
          } else
            throw t;
        }

      }
      dart.fn(testAnd, dynamicAnddynamicAnddynamicTodynamic());
      let isTrue = true;
      let isFalse = false;
      expect$.Expect.equals(true, testAnd(isTrue, isTrue, false));
      expect$.Expect.equals(false, testAnd(isTrue, 0, false));
      expect$.Expect.equals(false, testAnd(isTrue, 1, false));
      expect$.Expect.equals(false, testAnd(isTrue, "true", false));
      expect$.Expect.equals(false, testAnd(0, isTrue, false));
      expect$.Expect.equals(false, testAnd(1, isTrue, false));
      expect$.Expect.equals(true, testOr(isTrue, isTrue, false));
      expect$.Expect.equals(true, testOr(isFalse, isTrue, false));
      expect$.Expect.equals(true, testOr(isTrue, isFalse, false));
      expect$.Expect.equals(true, testOr(isTrue, 0, true));
      expect$.Expect.equals(true, testOr(isTrue, 1, true));
      expect$.Expect.equals(false, testOr(isFalse, 0, false));
      expect$.Expect.equals(false, testOr(isFalse, 1, false));
      expect$.Expect.equals(true, testOr(0, isTrue, true));
      expect$.Expect.equals(true, testOr(1, isTrue, true));
      expect$.Expect.equals(false, testOr(0, isFalse, false));
      expect$.Expect.equals(false, testOr(1, isFalse, false));
      let trueCount = 0, falseCount = 0;
      function trueFunc() {
        trueCount = dart.notNull(trueCount) + 1;
        return true;
      }
      dart.fn(trueFunc, VoidTobool());
      function falseFunc() {
        falseCount++;
        return false;
      }
      dart.fn(falseFunc, VoidTobool());
      expect$.Expect.equals(0, trueCount);
      expect$.Expect.equals(0, falseCount);
      dart.test(trueFunc()) && dart.test(trueFunc());
      expect$.Expect.equals(2, trueCount);
      expect$.Expect.equals(0, falseCount);
      trueCount = falseCount = 0;
      dart.test(falseFunc()) && dart.test(trueFunc());
      expect$.Expect.equals(0, trueCount);
      expect$.Expect.equals(1, falseCount);
      trueCount = falseCount = 0;
      dart.test(trueFunc()) && dart.test(falseFunc());
      expect$.Expect.equals(1, trueCount);
      expect$.Expect.equals(1, falseCount);
      trueCount = falseCount = 0;
      dart.test(falseFunc()) && dart.test(falseFunc());
      expect$.Expect.equals(0, trueCount);
      expect$.Expect.equals(1, falseCount);
      trueCount = falseCount = 0;
      dart.test(trueFunc()) || dart.test(trueFunc());
      expect$.Expect.equals(1, trueCount);
      expect$.Expect.equals(0, falseCount);
      trueCount = falseCount = 0;
      dart.test(falseFunc()) || dart.test(trueFunc());
      expect$.Expect.equals(1, trueCount);
      expect$.Expect.equals(1, falseCount);
      trueCount = falseCount = 0;
      dart.test(trueFunc()) || dart.test(falseFunc());
      expect$.Expect.equals(1, trueCount);
      expect$.Expect.equals(0, falseCount);
      trueCount = falseCount = 0;
      dart.test(falseFunc()) || dart.test(falseFunc());
      expect$.Expect.equals(0, trueCount);
      expect$.Expect.equals(2, falseCount);
    }
    static testMain() {
      bool_test.BoolTest.testEquality();
      bool_test.BoolTest.testNegate(true, false);
      bool_test.BoolTest.testToString();
      bool_test.BoolTest.testLogicalOp();
    }
  };
  dart.setSignature(bool_test.BoolTest, {
    statics: () => ({
      testEquality: dart.definiteFunctionType(dart.void, []),
      testToString: dart.definiteFunctionType(dart.void, []),
      testNegate: dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic]),
      testLogicalOp: dart.definiteFunctionType(dart.void, []),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testEquality', 'testToString', 'testNegate', 'testLogicalOp', 'testMain']
  });
  bool_test.main = function() {
    bool_test.BoolTest.testMain();
  };
  dart.fn(bool_test.main, VoidTodynamic());
  // Exports:
  exports.bool_test = bool_test;
});
