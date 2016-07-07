dart_library.library('language/number_syntax_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__number_syntax_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const number_syntax_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  number_syntax_test.NumberSyntaxTest = class NumberSyntaxTest extends core.Object {
    static testMain() {
      number_syntax_test.NumberSyntaxTest.testShortDoubleSyntax();
      number_syntax_test.NumberSyntaxTest.testDotSelectorSyntax();
    }
    static testShortDoubleSyntax() {
      expect$.Expect.equals(0.0, 0.0);
      expect$.Expect.equals(0.5, 0.5);
      expect$.Expect.equals(0.1234, 0.1234);
    }
    static testDotSelectorSyntax() {
      expect$.Expect.equals('0', dart.toString(0));
      expect$.Expect.equals('1', dart.toString(1));
      expect$.Expect.equals('123', dart.toString(123));
      expect$.Expect.equals('0', dart.toString(0));
      expect$.Expect.equals('1', dart.toString(1));
      expect$.Expect.equals('123', dart.toString(123));
      expect$.Expect.equals('0', dart.toString(0));
      expect$.Expect.equals('1', dart.toString(1));
      expect$.Expect.equals('123', dart.toString(123));
      expect$.Expect.equals(dart.toString(0.0), dart.toString(0.0));
      expect$.Expect.equals(dart.toString(0.1), dart.toString(0.1));
      expect$.Expect.equals(dart.toString(1.1), dart.toString(1.1));
      expect$.Expect.equals(dart.toString(123.4), dart.toString(123.4));
      expect$.Expect.equals(dart.toString(0.0), dart.toString(0.0));
      expect$.Expect.equals(dart.toString(0.1), dart.toString(0.1));
      expect$.Expect.equals(dart.toString(1.1), dart.toString(1.1));
      expect$.Expect.equals(dart.toString(123.4), dart.toString(123.4));
      expect$.Expect.equals(dart.toString(0.0), dart.toString(0.0));
      expect$.Expect.equals(dart.toString(0.1), dart.toString(0.1));
      expect$.Expect.equals(dart.toString(1.1), dart.toString(1.1));
      expect$.Expect.equals(dart.toString(123.4), dart.toString(123.4));
      expect$.Expect.equals(dart.toString(0.0), dart.toString(0.0));
      expect$.Expect.equals(dart.toString(10.0), dart.toString(10.0));
      expect$.Expect.equals(dart.toString(2.1e-34), dart.toString(2.1e-34));
    }
  };
  dart.setSignature(number_syntax_test.NumberSyntaxTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.void, []),
      testShortDoubleSyntax: dart.definiteFunctionType(dart.void, []),
      testDotSelectorSyntax: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testMain', 'testShortDoubleSyntax', 'testDotSelectorSyntax']
  });
  number_syntax_test.main = function() {
    number_syntax_test.NumberSyntaxTest.testMain();
  };
  dart.fn(number_syntax_test.main, VoidTodynamic());
  // Exports:
  exports.number_syntax_test = number_syntax_test;
});
