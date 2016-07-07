dart_library.library('language/index_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__index_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const index_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  index_test.Helper = class Helper extends core.Object {
    static fibonacci(n) {
      let a = 0, b = 1, i = 0;
      while (i++ < dart.notNull(n)) {
        a = a + b;
        b = a - b;
      }
      return a;
    }
  };
  dart.setSignature(index_test.Helper, {
    statics: () => ({fibonacci: dart.definiteFunctionType(core.int, [core.int])}),
    names: ['fibonacci']
  });
  index_test.IndexTest = class IndexTest extends core.Object {
    static testMain() {
      let a = core.List.new(10);
      expect$.Expect.equals(10, a[dartx.length]);
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, index_test.Helper.fibonacci(i));
      }
      a[dartx.set](index_test.IndexTest.ID_IDLE, index_test.Helper.fibonacci(0));
      for (let i = 2; i < dart.notNull(a[dartx.length]); i++) {
        expect$.Expect.equals(dart.dsend(a[dartx.get](i - 2), '+', a[dartx.get](i - 1)), a[dartx.get](i));
      }
      expect$.Expect.equals(515, a[dartx.set](3, 515));
    }
  };
  dart.setSignature(index_test.IndexTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  index_test.IndexTest.ID_IDLE = 0;
  index_test.main = function() {
    index_test.IndexTest.testMain();
  };
  dart.fn(index_test.main, VoidTodynamic());
  // Exports:
  exports.index_test = index_test;
});
