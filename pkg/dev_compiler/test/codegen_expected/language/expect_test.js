dart_library.library('language/expect_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__expect_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const expect_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  expect_test.ExpectTest = class ExpectTest extends core.Object {
    static testEquals(a) {
      try {
        expect$.Expect.equals("AB", a, "within testEquals");
      } catch (msg) {
        if (core.Exception.is(msg)) {
          core.print(msg);
          return;
        } else
          throw msg;
      }

      expect$.Expect.equals("AB", dart.str`${a}B`);
      dart.throw("Expect.equals did not fail");
    }
    static testIsTrue(f) {
      try {
        expect$.Expect.isTrue(f);
      } catch (msg) {
        if (core.Exception.is(msg)) {
          core.print(msg);
          return;
        } else
          throw msg;
      }

      expect$.Expect.isFalse(f);
      dart.throw("Expect.isTrue did not fail");
    }
    static testIsFalse(t) {
      try {
        expect$.Expect.isFalse(t);
      } catch (msg) {
        if (core.Exception.is(msg)) {
          core.print(msg);
          return;
        } else
          throw msg;
      }

      expect$.Expect.isTrue(t);
      dart.throw("Expect.isFalse did not fail");
    }
    static testIdentical(a) {
      let ab = dart.str`${a}B`;
      try {
        expect$.Expect.identical("AB", ab);
      } catch (msg) {
        if (core.Exception.is(msg)) {
          core.print(msg);
          return;
        } else
          throw msg;
      }

      expect$.Expect.equals("AB", ab);
      dart.throw("Expect.identical did not fail");
    }
    static testFail() {
      try {
        expect$.Expect.fail("fail now");
      } catch (msg) {
        if (core.Exception.is(msg)) {
          core.print(msg);
          return;
        } else
          throw msg;
      }

      dart.throw("Expect.fail did not fail");
    }
    static testMain() {
      expect_test.ExpectTest.testEquals("A");
      expect_test.ExpectTest.testIsTrue(false);
      expect_test.ExpectTest.testIsTrue(1);
      expect_test.ExpectTest.testIsFalse(true);
      expect_test.ExpectTest.testIsFalse(0);
      expect_test.ExpectTest.testIdentical("A");
      expect_test.ExpectTest.testFail();
    }
  };
  dart.setSignature(expect_test.ExpectTest, {
    statics: () => ({
      testEquals: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testIsTrue: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testIsFalse: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testIdentical: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testFail: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testEquals', 'testIsTrue', 'testIsFalse', 'testIdentical', 'testFail', 'testMain']
  });
  expect_test.main = function() {
    expect_test.ExpectTest.testMain();
  };
  dart.fn(expect_test.main, VoidTodynamic());
  // Exports:
  exports.expect_test = expect_test;
});
