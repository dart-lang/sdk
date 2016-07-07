dart_library.library('language/statement_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__statement_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const statement_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  statement_test.StatementTest = class StatementTest extends core.Object {
    new() {
    }
    static testMain() {
      let test = new statement_test.StatementTest();
      test.testIfStatement();
      test.testForLoop();
      test.testWhileLoops();
      test.testSwitch();
      test.testExceptions();
      test.testBreak();
      test.testContinue();
      test.testFunction();
      test.testReturn();
    }
    testIfStatement() {
      if (true) {
        expect$.Expect.equals(true, true);
      } else {
        expect$.Expect.equals(false, true);
      }
      if (false) {
        expect$.Expect.equals(false, true);
      } else {
        expect$.Expect.equals(true, true);
      }
    }
    testForLoop() {
      let count = 0, count2 = null;
      for (let i = 0; i < 10; ++i) {
        count = dart.notNull(count) + 1;
      }
      expect$.Expect.equals(10, count);
      count2 = 0;
      for (count = 0; dart.notNull(count) < 5; count = dart.notNull(count) + 1) {
        count2 = dart.notNull(count2) + 1;
      }
      expect$.Expect.equals(5, count);
      expect$.Expect.equals(5, count2);
      count = count2 = 0;
      for (; dart.notNull(count) < 10; count = dart.notNull(count) + 1) {
        count2 = dart.notNull(count2) + 1;
      }
      expect$.Expect.equals(10, count);
      expect$.Expect.equals(10, count2);
      for (count = 0; dart.notNull(count) < 5;) {
        count = dart.notNull(count) + 1;
      }
      expect$.Expect.equals(5, count);
      for (count = 0;; count = dart.notNull(count) + 1) {
        if (count == 10) {
          break;
        }
      }
      expect$.Expect.equals(10, count);
      count = 0;
      for (;;) {
        if (count == 5) {
          break;
        }
        count = dart.notNull(count) + 1;
      }
      expect$.Expect.equals(5, count);
    }
    testWhileLoops() {
      let count = 0;
      while (count < 10) {
        ++count;
      }
      expect$.Expect.equals(10, count);
      count = 0;
      do {
        ++count;
      } while (count < 5);
      expect$.Expect.equals(5, count);
    }
    testSwitch() {
      let hit0 = null, hit1 = null, hitDefault = null;
      for (let x = 0; x < 3; ++x) {
        switch (x) {
          case 0:
          {
            hit0 = true;
            break;
          }
          case 1:
          {
            hit1 = true;
            break;
          }
          default:
          {
            hitDefault = true;
            break;
          }
        }
      }
      expect$.Expect.equals(true, hit0);
      expect$.Expect.equals(true, hit1);
      expect$.Expect.equals(true, hitDefault);
      let strings = JSArrayOfString().of(['a', 'b', 'c']);
      let hitA = null, hitB = null;
      hitDefault = false;
      for (let x = 0; x < 3; ++x) {
        switch (strings[dartx.get](x)) {
          case 'a':
          {
            hitA = true;
            break;
          }
          case 'b':
          {
            hitB = true;
            break;
          }
          default:
          {
            hitDefault = true;
            break;
          }
        }
      }
      expect$.Expect.equals(true, hitA);
      expect$.Expect.equals(true, hitB);
      expect$.Expect.equals(true, hitDefault);
    }
    testExceptions() {
      let hitCatch = null, hitFinally = null;
      try {
        dart.throw("foo");
      } catch (e) {
        expect$.Expect.equals(true, dart.equals(e, "foo"));
        hitCatch = true;
      }
 finally {
        hitFinally = true;
      }
      expect$.Expect.equals(true, hitCatch);
      expect$.Expect.equals(true, hitFinally);
    }
    testBreak() {
      let ints = JSArrayOfListOfint().of([JSArrayOfint().of([32, 87, 3, 589]), JSArrayOfint().of([12, 1076, 2000, 8]), JSArrayOfint().of([622, 127, 77, 955])]);
      let i = null, j = 0;
      let foundIt = false;
      search:
        for (i = 0; dart.notNull(i) < dart.notNull(ints[dartx.length]); i = dart.notNull(i) + 1) {
          for (j = 0; j < dart.notNull(ints[dartx.get](i)[dartx.length]); j++) {
            if (ints[dartx.get](i)[dartx.get](j) == 12) {
              foundIt = true;
              break search;
            }
          }
        }
      expect$.Expect.equals(true, foundIt);
    }
    testContinue() {
      let searchMe = "Look for a substring in me";
      let substring = "sub";
      let foundIt = false;
      let max = dart.notNull(searchMe[dartx.length]) - dart.notNull(substring[dartx.length]);
      test:
        for (let i = 0; i <= max; i++) {
          let n = substring[dartx.length];
          let j = i;
          let k = 0;
          while ((() => {
            let x = n;
            n = dart.notNull(x) - 1;
            return x;
          })() != 0) {
            if (searchMe[dartx.get](j++) != substring[dartx.get](k++)) {
              continue test;
            }
          }
          foundIt = true;
          break test;
        }
    }
    testFunction() {
      function foo() {
        return 42;
      }
      dart.fn(foo, VoidToint());
      expect$.Expect.equals(42, foo());
    }
    testReturn() {
      if (true) {
        return;
      }
      expect$.Expect.equals(true, false);
    }
  };
  dart.setSignature(statement_test.StatementTest, {
    constructors: () => ({new: dart.definiteFunctionType(statement_test.StatementTest, [])}),
    methods: () => ({
      testIfStatement: dart.definiteFunctionType(dart.dynamic, []),
      testForLoop: dart.definiteFunctionType(dart.dynamic, []),
      testWhileLoops: dart.definiteFunctionType(dart.dynamic, []),
      testSwitch: dart.definiteFunctionType(dart.dynamic, []),
      testExceptions: dart.definiteFunctionType(dart.dynamic, []),
      testBreak: dart.definiteFunctionType(dart.dynamic, []),
      testContinue: dart.definiteFunctionType(dart.dynamic, []),
      testFunction: dart.definiteFunctionType(dart.dynamic, []),
      testReturn: dart.definiteFunctionType(dart.void, [])
    }),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  statement_test.main = function() {
    statement_test.StatementTest.testMain();
  };
  dart.fn(statement_test.main, VoidTodynamic());
  // Exports:
  exports.statement_test = statement_test;
});
