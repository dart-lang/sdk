dart_library.library('corelib/list_literal_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_literal_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_literal_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_literal_test.ListLiteralTest = class ListLiteralTest extends core.Object {
    static testMain() {
      let list = JSArrayOfint().of([1, 2, 3]);
      expect$.Expect.equals(3, list[dartx.length]);
      list[dartx.add](4);
      expect$.Expect.equals(4, list[dartx.length]);
      list[dartx.addAll](JSArrayOfint().of([5, 6]));
      expect$.Expect.equals(6, list[dartx.length]);
      list[dartx.set](0, 0);
      expect$.Expect.equals(0, list[dartx.get](0));
    }
  };
  dart.setSignature(list_literal_test.ListLiteralTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  list_literal_test.main = function() {
    list_literal_test.ListLiteralTest.testMain();
  };
  dart.fn(list_literal_test.main, VoidTodynamic());
  // Exports:
  exports.list_literal_test = list_literal_test;
});
