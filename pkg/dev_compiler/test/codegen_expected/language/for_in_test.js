dart_library.library('language/for_in_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__for_in_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const for_in_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let JSArrayOfListOfString = () => (JSArrayOfListOfString = dart.constFn(_interceptors.JSArray$(ListOfString())))();
  let ListOfListOfString = () => (ListOfListOfString = dart.constFn(core.List$(ListOfString())))();
  let JSArrayOfListOfListOfString = () => (JSArrayOfListOfListOfString = dart.constFn(_interceptors.JSArray$(ListOfListOfString())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  for_in_test.ForInTest = class ForInTest extends core.Object {
    static testMain() {
      for_in_test.ForInTest.testSimple();
      for_in_test.ForInTest.testGenericSyntax1();
      for_in_test.ForInTest.testGenericSyntax2();
      for_in_test.ForInTest.testGenericSyntax3();
      for_in_test.ForInTest.testGenericSyntax4();
    }
    static testSimple() {
      let list = JSArrayOfint().of([1, 3, 5]);
      let sum = 0;
      for (let i of list) {
        sum = sum + dart.notNull(i);
      }
      expect$.Expect.equals(9, sum);
    }
    static testGenericSyntax1() {
      let aCollection = JSArrayOfListOfString().of([]);
      for (let strArrArr of aCollection) {
      }
    }
    static testGenericSyntax2() {
      let aCollection = JSArrayOfListOfString().of([]);
      let strArrArr = null;
      for (strArrArr of aCollection) {
      }
    }
    static testGenericSyntax3() {
      let aCollection = JSArrayOfListOfListOfString().of([]);
      for (let strArrArr of aCollection) {
      }
    }
    static testGenericSyntax4() {
      let aCollection = JSArrayOfListOfListOfString().of([]);
      let strArrArr = null;
      for (strArrArr of aCollection) {
      }
    }
  };
  dart.setSignature(for_in_test.ForInTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.dynamic, []),
      testSimple: dart.definiteFunctionType(dart.void, []),
      testGenericSyntax1: dart.definiteFunctionType(dart.void, []),
      testGenericSyntax2: dart.definiteFunctionType(dart.void, []),
      testGenericSyntax3: dart.definiteFunctionType(dart.void, []),
      testGenericSyntax4: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testMain', 'testSimple', 'testGenericSyntax1', 'testGenericSyntax2', 'testGenericSyntax3', 'testGenericSyntax4']
  });
  for_in_test.main = function() {
    for_in_test.ForInTest.testMain();
  };
  dart.fn(for_in_test.main, VoidTodynamic());
  // Exports:
  exports.for_in_test = for_in_test;
});
