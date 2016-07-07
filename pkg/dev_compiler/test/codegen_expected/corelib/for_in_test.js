dart_library.library('corelib/for_in_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__for_in_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const for_in_test = Object.create(null);
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let ListOfFunction = () => (ListOfFunction = dart.constFn(core.List$(core.Function)))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  for_in_test.ForInTest = class ForInTest extends core.Object {
    static testMain() {
      for_in_test.ForInTest.testSimple();
      for_in_test.ForInTest.testBreak();
      for_in_test.ForInTest.testContinue();
      for_in_test.ForInTest.testClosure();
    }
    static getSmallSet() {
      let set = SetOfint().new();
      set.add(1);
      set.add(2);
      set.add(4);
      return set;
    }
    static testSimple() {
      let set = for_in_test.ForInTest.getSmallSet();
      let count = 0;
      for (let i of set) {
        count = count + dart.notNull(i);
      }
      expect$.Expect.equals(7, count);
      count = 0;
      for (let i of set) {
        count = count + dart.notNull(i);
      }
      expect$.Expect.equals(7, count);
      count = 0;
      for (let i of set) {
        count = count + dart.notNull(i);
      }
      expect$.Expect.equals(7, count);
      count = 0;
      for (let i of set) {
        count = count + dart.notNull(i);
      }
      expect$.Expect.equals(7, count);
      count = 0;
      let i = 0;
      expect$.Expect.equals(false, set.contains(i));
      for (i of set) {
        count = count + i;
      }
      expect$.Expect.equals(7, count);
      expect$.Expect.equals(true, set.contains(i));
      expect$.Expect.equals(4, i);
    }
    static testBreak() {
      let set = for_in_test.ForInTest.getSmallSet();
      let count = 0;
      for (let i of set) {
        if (i == 4) break;
        count = count + dart.notNull(i);
      }
      expect$.Expect.equals(true, count < 4);
    }
    static testContinue() {
      let set = for_in_test.ForInTest.getSmallSet();
      let count = 0;
      for (let i of set) {
        if (dart.notNull(i) < 4) continue;
        count = count + dart.notNull(i);
      }
      expect$.Expect.equals(4, count);
    }
    static testClosure() {
      let set = for_in_test.ForInTest.getSmallSet();
      let closures = ListOfFunction().new(set.length);
      let index = 0;
      for (let i of set) {
        closures[dartx.set](index++, dart.fn(() => i, VoidToint()));
      }
      expect$.Expect.equals(index, set.length);
      expect$.Expect.equals(7, dart.dsend(dart.dsend(dart.dcall(closures[dartx.get](0)), '+', dart.dcall(closures[dartx.get](1))), '+', dart.dcall(closures[dartx.get](2))));
    }
  };
  dart.setSignature(for_in_test.ForInTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.dynamic, []),
      getSmallSet: dart.definiteFunctionType(core.Set$(core.int), []),
      testSimple: dart.definiteFunctionType(dart.void, []),
      testBreak: dart.definiteFunctionType(dart.void, []),
      testContinue: dart.definiteFunctionType(dart.void, []),
      testClosure: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testMain', 'getSmallSet', 'testSimple', 'testBreak', 'testContinue', 'testClosure']
  });
  for_in_test.main = function() {
    for_in_test.ForInTest.testMain();
  };
  dart.fn(for_in_test.main, VoidTodynamic());
  // Exports:
  exports.for_in_test = for_in_test;
});
