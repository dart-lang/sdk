dart_library.library('language/list_literal2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_literal2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_literal2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_literal2_test.ArrayLiteral2Test = class ArrayLiteral2Test extends core.Object {
    static testMain() {
      expect$.Expect.equals(2, list_literal2_test.ArrayLiteral2Test.LUCKY_DOG[dartx.length]);
      expect$.Expect.equals(2, list_literal2_test.ArrayLiteral2Test.MUSIC_BOX[dartx.length]);
      expect$.Expect.equals(1919, list_literal2_test.ArrayLiteral2Test.LUCKY_DOG[dartx.get](0));
      expect$.Expect.equals(1921, list_literal2_test.ArrayLiteral2Test.LUCKY_DOG[dartx.get](1));
      expect$.Expect.equals(list_literal2_test.ArrayLiteral2Test.LAUREL, list_literal2_test.ArrayLiteral2Test.MUSIC_BOX[dartx.get](0));
      expect$.Expect.equals(list_literal2_test.ArrayLiteral2Test.HARDY, list_literal2_test.ArrayLiteral2Test.MUSIC_BOX[dartx.get](1));
    }
  };
  dart.setSignature(list_literal2_test.ArrayLiteral2Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  list_literal2_test.ArrayLiteral2Test.LAUREL = 1965;
  list_literal2_test.ArrayLiteral2Test.HARDY = 1957;
  list_literal2_test.ArrayLiteral2Test.LUCKY_DOG = dart.constList([1919, 1921], core.int);
  dart.defineLazy(list_literal2_test.ArrayLiteral2Test, {
    get MUSIC_BOX() {
      return dart.constList([list_literal2_test.ArrayLiteral2Test.LAUREL, list_literal2_test.ArrayLiteral2Test.HARDY], core.int);
    }
  });
  list_literal2_test.main = function() {
    list_literal2_test.ArrayLiteral2Test.testMain();
  };
  dart.fn(list_literal2_test.main, VoidTodynamic());
  // Exports:
  exports.list_literal2_test = list_literal2_test;
});
