dart_library.library('language/string_escapes_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_escapes_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_escapes_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_escapes_test.StringEscapesTest = class StringEscapesTest extends core.Object {
    static testMain() {
      string_escapes_test.StringEscapesTest.testDelimited();
      string_escapes_test.StringEscapesTest.testFixed2();
      string_escapes_test.StringEscapesTest.testFixed4();
      string_escapes_test.StringEscapesTest.testEscapes();
      string_escapes_test.StringEscapesTest.testLiteral();
    }
    static testDelimited() {
      let str = "FooBarBaz퟿Boo";
      expect$.Expect.equals(15, str[dartx.length]);
      expect$.Expect.equals(1, str[dartx.codeUnitAt](3));
      expect$.Expect.equals(1, str[dartx.codeUnitAt](7));
      expect$.Expect.equals(55295, str[dartx.codeUnitAt](11));
      expect$.Expect.equals('B'[dartx.codeUnitAt](0), str[dartx.codeUnitAt](12));
    }
    static testEscapes() {
      let str = "Foo\fBar\vBaz\bBoo";
      expect$.Expect.equals(15, str[dartx.length]);
      expect$.Expect.equals(12, str[dartx.codeUnitAt](3));
      expect$.Expect.equals('B'[dartx.codeUnitAt](0), str[dartx.codeUnitAt](4));
      expect$.Expect.equals(11, str[dartx.codeUnitAt](7));
      expect$.Expect.equals('z'[dartx.codeUnitAt](0), str[dartx.codeUnitAt](10));
      expect$.Expect.equals(8, str[dartx.codeUnitAt](11));
      expect$.Expect.equals('o'[dartx.codeUnitAt](0), str[dartx.codeUnitAt](14));
      str = "Abc\rDef\nGhi\tJkl";
      expect$.Expect.equals(15, str[dartx.length]);
      expect$.Expect.equals(13, str[dartx.codeUnitAt](3));
      expect$.Expect.equals('D'[dartx.codeUnitAt](0), str[dartx.codeUnitAt](4));
      expect$.Expect.equals(10, str[dartx.codeUnitAt](7));
      expect$.Expect.equals('G'[dartx.codeUnitAt](0), str[dartx.codeUnitAt](8));
      expect$.Expect.equals(9, str[dartx.codeUnitAt](11));
      expect$.Expect.equals('J'[dartx.codeUnitAt](0), str[dartx.codeUnitAt](12));
    }
    static testFixed2() {
      let str = "FooÿBar";
      expect$.Expect.equals(7, str[dartx.length]);
      expect$.Expect.equals(255, str[dartx.codeUnitAt](3));
      expect$.Expect.equals('B'[dartx.codeUnitAt](0), str[dartx.codeUnitAt](4));
    }
    static testFixed4() {
      let str = "FooBar";
      expect$.Expect.equals(7, str[dartx.length]);
      expect$.Expect.equals(1, str[dartx.codeUnitAt](3));
      expect$.Expect.equals('B'[dartx.codeUnitAt](0), str[dartx.codeUnitAt](4));
    }
    static testLiteral() {
      let str = "acdeghijkl${}\"";
      expect$.Expect.equals('acdeghijkl${}"', str);
    }
  };
  dart.setSignature(string_escapes_test.StringEscapesTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.dynamic, []),
      testDelimited: dart.definiteFunctionType(dart.dynamic, []),
      testEscapes: dart.definiteFunctionType(dart.dynamic, []),
      testFixed2: dart.definiteFunctionType(dart.dynamic, []),
      testFixed4: dart.definiteFunctionType(dart.dynamic, []),
      testLiteral: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['testMain', 'testDelimited', 'testEscapes', 'testFixed2', 'testFixed4', 'testLiteral']
  });
  string_escapes_test.main = function() {
    string_escapes_test.StringEscapesTest.testMain();
  };
  dart.fn(string_escapes_test.main, VoidTodynamic());
  // Exports:
  exports.string_escapes_test = string_escapes_test;
});
